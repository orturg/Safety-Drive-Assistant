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

    nonisolated private static let imageOrientation: CGImagePropertyOrientation = .leftMirrored

    nonisolated func process(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: Self.imageOrientation, options: [:])

        do {
            try handler.perform([request])
        } catch {
            publish(detected: false, boundingBox: .zero)
            return
        }

        guard let face = request.results?.first else {
            publish(detected: false, boundingBox: .zero)
            return
        }

        publish(detected: true, boundingBox: face.boundingBox)
    }

    nonisolated private func publish(detected: Bool, boundingBox: CGRect) {
        DispatchQueue.main.async { [weak self] in
            self?.isFaceDetected = detected
            self?.faceBoundingBox = boundingBox
        }
    }
}
