//
//  FaceDetector.swift
//  Safety-Drive-Assistant
//
//  Created by Illia Antypenko on 10.06.2026.
//

import Vision
import AVFoundation
import Combine

final class FaceDetector: ObservableObject {

    enum CalibrationState: Equatable {
        case idle
        case calibrating(progress: Double)
        case calibrated
    }

    struct DriverAlert: Equatable {
        let type: AlertType
        let reason: AlertReason
    }

    private struct EyeSample {
        let time: Date
        let closed: Bool
    }

    @Published private(set) var isFaceDetected = false
    @Published private(set) var faceBoundingBox: CGRect = .zero
    @Published private(set) var eyeAspectRatio: Double = 0
    @Published private(set) var calibrationState: CalibrationState = .idle
    @Published private(set) var baseline: Double = 0
    @Published private(set) var closedEyeThreshold: Double = 0
    @Published private(set) var eyesClosed = false
    @Published private(set) var perclos: Double = 0
    @Published private(set) var headPitch: Double = 0
    @Published private(set) var headYaw: Double = 0
    @Published private(set) var isHeadDown = false
    @Published private(set) var isTripActive = false
    @Published private(set) var alert: DriverAlert?

    var isCalibrationEnabled: Bool = false

    private let calibrationDuration: TimeInterval = 3
    private let closedEyeRatio = 0.75
    private let perclosWindow: TimeInterval = 15
    private let headDownThreshold: Double = 12
    private let warningAfter: TimeInterval = 1.2
    private let criticalAfter: TimeInterval = 2.5
    private let faceLostWarningAfter: TimeInterval = 2.0
    private let faceLostCriticalAfter: TimeInterval = 4.0
    private let perclosWarning: Double = 0.35

    private var calibrationSamples: [Double] = []
    private var calibrationPitchSamples: [Double] = []
    private var calibrationStartedAt: Date?
    private var eyeSamples: [EyeSample] = []
    private var neutralPitch: Double = 0
    private var eyesClosedSince: Date?
    private var headDownSince: Date?
    private var faceLostSince: Date?

    nonisolated private static let imageOrientation: CGImagePropertyOrientation = .leftMirrored

    func startTrip() {
        isTripActive = true
        clearHazardTimers()
        alert = nil
    }

    nonisolated func process(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: Self.imageOrientation, options: [:])

        do {
            try handler.perform([request])
        } catch {
            deliver(faceDetected: false, eyeAspectRatio: 0, pitch: 0, yaw: 0, boundingBox: .zero)
            return
        }

        guard let face = request.results?.first else {
            deliver(faceDetected: false, eyeAspectRatio: 0, pitch: 0, yaw: 0, boundingBox: .zero)
            return
        }

        deliver(faceDetected: true,
                eyeAspectRatio: averageEyeAspectRatio(for: face),
                pitch: degrees(from: face.pitch),
                yaw: degrees(from: face.yaw),
                boundingBox: face.boundingBox)
    }

    nonisolated private func deliver(faceDetected: Bool, eyeAspectRatio: Double, pitch: Double, yaw: Double, boundingBox: CGRect) {
        DispatchQueue.main.async { [weak self] in
            self?.consume(faceDetected: faceDetected, eyeAspectRatio: eyeAspectRatio, pitch: pitch, yaw: yaw, boundingBox: boundingBox)
        }
    }

    private func consume(faceDetected: Bool, eyeAspectRatio: Double, pitch: Double, yaw: Double, boundingBox: CGRect) {
        isFaceDetected = faceDetected
        faceBoundingBox = boundingBox
        self.eyeAspectRatio = eyeAspectRatio
        headPitch = pitch
        headYaw = yaw

        if faceDetected {
            switch calibrationState {
            case .idle:
                if isCalibrationEnabled {
                    startCalibration(eyeAspectRatio: eyeAspectRatio, pitch: pitch)
                }
            case .calibrating:
                updateCalibration(eyeAspectRatio: eyeAspectRatio, pitch: pitch)
            case .calibrated:
                let nowClosed = eyeAspectRatio < closedEyeThreshold
                if eyesClosed, !nowClosed,
                   let since = eyesClosedSince,
                   Date().timeIntervalSince(since) >= warningAfter {
                    eyeSamples.removeAll()
                    perclos = 0
                }
                eyesClosed = nowClosed
                isHeadDown = (neutralPitch - pitch) > headDownThreshold
                updatePerclos(closed: eyesClosed)
            }
        } else {
            eyesClosed = false
            isHeadDown = false
            if case .calibrating = calibrationState {
                resetCalibration()
            }
        }

        evaluateAlert()
    }

    private func startCalibration(eyeAspectRatio: Double, pitch: Double) {
        calibrationStartedAt = Date()
        calibrationSamples = [eyeAspectRatio]
        calibrationPitchSamples = [pitch]
        calibrationState = .calibrating(progress: 0)
    }

    private func updateCalibration(eyeAspectRatio: Double, pitch: Double) {
        calibrationSamples.append(eyeAspectRatio)
        calibrationPitchSamples.append(pitch)

        let elapsed = Date().timeIntervalSince(calibrationStartedAt ?? Date())
        let progress = min(elapsed / calibrationDuration, 1)

        if progress >= 1 {
            finishCalibration()
        } else {
            calibrationState = .calibrating(progress: progress)
        }
    }

    private func finishCalibration() {
        guard !calibrationSamples.isEmpty else {
            resetCalibration()
            return
        }

        baseline = median(of: calibrationSamples)
        closedEyeThreshold = baseline * closedEyeRatio
        neutralPitch = median(of: calibrationPitchSamples)
        calibrationState = .calibrated
        calibrationSamples = []
        calibrationPitchSamples = []
        calibrationStartedAt = nil
    }

    private func resetCalibration() {
        calibrationState = .idle
        calibrationSamples = []
        calibrationPitchSamples = []
        calibrationStartedAt = nil
        eyeSamples = []
        perclos = 0
    }

    private func updatePerclos(closed: Bool) {
        let now = Date()
        eyeSamples.append(EyeSample(time: now, closed: closed))

        let cutoff = now.addingTimeInterval(-perclosWindow)
        eyeSamples.removeAll { $0.time < cutoff }

        let closedCount = eyeSamples.filter(\.closed).count
        perclos = eyeSamples.isEmpty ? 0 : Double(closedCount) / Double(eyeSamples.count)
    }

    private func evaluateAlert() {
        guard case .calibrated = calibrationState, isTripActive else {
            clearHazardTimers()
            if alert != nil { alert = nil }
            return
        }

        let now = Date()
        updateHazardTimer(&eyesClosedSince, active: isFaceDetected && eyesClosed, now: now)
        updateHazardTimer(&headDownSince, active: isFaceDetected && isHeadDown, now: now)
        updateHazardTimer(&faceLostSince, active: !isFaceDetected, now: now)

        let newAlert = strongestAlert(now: now)
        if newAlert != alert {
            alert = newAlert
        }
    }

    private func updateHazardTimer(_ since: inout Date?, active: Bool, now: Date) {
        if active {
            if since == nil { since = now }
        } else {
            since = nil
        }
    }

    private func strongestAlert(now: Date) -> DriverAlert? {
        let hazards: [(reason: AlertReason, since: Date?, warn: TimeInterval, critical: TimeInterval)] = [
            (.eyesClosed, eyesClosedSince, warningAfter, criticalAfter),
            (.headDown, headDownSince, warningAfter, criticalAfter),
            (.faceLost, faceLostSince, faceLostWarningAfter, faceLostCriticalAfter)
        ]

        func duration(_ since: Date?) -> TimeInterval {
            guard let since else { return 0 }
            return now.timeIntervalSince(since)
        }

        if let hazard = hazards.first(where: { duration($0.since) >= $0.critical }) {
            return DriverAlert(type: .critical, reason: hazard.reason)
        }
        if let hazard = hazards.first(where: { duration($0.since) >= $0.warn }) {
            return DriverAlert(type: .warning, reason: hazard.reason)
        }
        if perclos >= perclosWarning {
            return DriverAlert(type: .warning, reason: .eyesClosed)
        }
        return nil
    }

    private func clearHazardTimers() {
        eyesClosedSince = nil
        headDownSince = nil
        faceLostSince = nil
    }

    private func median(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }

    nonisolated private func degrees(from value: NSNumber?) -> Double {
        guard let radians = value?.doubleValue else { return 0 }
        return radians * 180 / .pi
    }

    nonisolated private func averageEyeAspectRatio(for face: VNFaceObservation) -> Double {
        guard let landmarks = face.landmarks else { return 0 }

        let ratios = [landmarks.leftEye, landmarks.rightEye].compactMap { eye in
            eye.flatMap { aspectRatio(of: $0, boundingBox: face.boundingBox) }
        }

        guard !ratios.isEmpty else { return 0 }
        return ratios.reduce(0, +) / Double(ratios.count)
    }

    nonisolated private func aspectRatio(of eye: VNFaceLandmarkRegion2D, boundingBox: CGRect) -> Double? {
        let points = eye.normalizedPoints
        guard points.count >= 4 else { return nil }

        let xs = points.map { Double($0.x) * Double(boundingBox.width) }
        let ys = points.map { Double($0.y) * Double(boundingBox.height) }

        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return nil }

        let width = maxX - minX
        guard width > 0 else { return nil }

        return (maxY - minY) / width
    }
}

