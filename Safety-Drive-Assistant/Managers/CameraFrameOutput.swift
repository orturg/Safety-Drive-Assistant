//
//  CameraFrameOutput.swift
//  Safety-Drive-Assistant
//
//  Created by Illia Antypenko on 10.06.2026.
//

import AVFoundation

nonisolated final class CameraFrameOutput: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    private let onSampleBuffer: (CMSampleBuffer) -> Void

    init(onSampleBuffer: @escaping (CMSampleBuffer) -> Void) {
        self.onSampleBuffer = onSampleBuffer
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onSampleBuffer(sampleBuffer)
    }
}
