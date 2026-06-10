//
//  CameraSessionManager.swift
//  Safety-Drive-Assistant
//
//  Created by Artur Nozhenko on 04.06.2026.
//

import Foundation
import AVFoundation
import Combine

final class CameraSessionManager: ObservableObject {

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let frameOutput: CameraFrameOutput
    private var isConfigured = false

    init(onSampleBuffer: @escaping (CMSampleBuffer) -> Void = { _ in }) {
        frameOutput = CameraFrameOutput(onSampleBuffer: onSampleBuffer)
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configureIfNeeded()
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(frameOutput, queue: videoOutputQueue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
        isConfigured = true
    }
}

