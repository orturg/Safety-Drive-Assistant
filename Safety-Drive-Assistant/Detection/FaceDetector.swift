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

    private let calibrationDuration: TimeInterval = 3
    private let closedEyeRatio = 0.75
    private let perclosWindow: TimeInterval = 15

    private var calibrationSamples: [Double] = []
    private var calibrationStartedAt: Date?
    private var eyeSamples: [EyeSample] = []

    nonisolated private static let imageOrientation: CGImagePropertyOrientation = .leftMirrored

    nonisolated func process(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: Self.imageOrientation, options: [:])

        do {
            try handler.perform([request])
        } catch {
            deliver(faceDetected: false, eyeAspectRatio: 0, boundingBox: .zero)
            return
        }

        guard let face = request.results?.first else {
            deliver(faceDetected: false, eyeAspectRatio: 0, boundingBox: .zero)
            return
        }

        deliver(faceDetected: true, eyeAspectRatio: averageEyeAspectRatio(for: face), boundingBox: face.boundingBox)
    }

    nonisolated private func deliver(faceDetected: Bool, eyeAspectRatio: Double, boundingBox: CGRect) {
        DispatchQueue.main.async { [weak self] in
            self?.consume(faceDetected: faceDetected, eyeAspectRatio: eyeAspectRatio, boundingBox: boundingBox)
        }
    }

    private func consume(faceDetected: Bool, eyeAspectRatio: Double, boundingBox: CGRect) {
        isFaceDetected = faceDetected
        faceBoundingBox = boundingBox
        self.eyeAspectRatio = eyeAspectRatio

        guard faceDetected else {
            eyesClosed = false
            if case .calibrating = calibrationState {
                resetCalibration()
            }
            return
        }

        switch calibrationState {
        case .idle:
            startCalibration(with: eyeAspectRatio)
        case .calibrating:
            updateCalibration(with: eyeAspectRatio)
        case .calibrated:
            eyesClosed = eyeAspectRatio < closedEyeThreshold
            updatePerclos(closed: eyesClosed)
        }
    }

    private func startCalibration(with sample: Double) {
        calibrationStartedAt = Date()
        calibrationSamples = [sample]
        calibrationState = .calibrating(progress: 0)
    }

    private func updateCalibration(with sample: Double) {
        calibrationSamples.append(sample)

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

        let sorted = calibrationSamples.sorted()
        let median = sorted[sorted.count / 2]

        baseline = median
        closedEyeThreshold = median * closedEyeRatio
        calibrationState = .calibrated
        calibrationSamples = []
        calibrationStartedAt = nil
    }

    private func resetCalibration() {
        calibrationState = .idle
        calibrationSamples = []
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
