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

    @Published private(set) var isFaceDetected = false
    @Published private(set) var faceBoundingBox: CGRect = .zero
    @Published private(set) var eyeAspectRatio: Double = 0

    nonisolated private static let imageOrientation: CGImagePropertyOrientation = .leftMirrored

    nonisolated func process(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: Self.imageOrientation, options: [:])

        do {
            try handler.perform([request])
        } catch {
            publish(detected: false, boundingBox: .zero, eyeAspectRatio: 0)
            return
        }

        guard let face = request.results?.first else {
            publish(detected: false, boundingBox: .zero, eyeAspectRatio: 0)
            return
        }

        publish(detected: true, boundingBox: face.boundingBox, eyeAspectRatio: averageEyeAspectRatio(for: face))
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

    nonisolated private func publish(detected: Bool, boundingBox: CGRect, eyeAspectRatio: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.isFaceDetected = detected
            self?.faceBoundingBox = boundingBox
            self?.eyeAspectRatio = eyeAspectRatio
        }
    }
}
