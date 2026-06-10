//
//  CameraScreen.swift
//  Safety-Drive-Assistant
//
//  Created by Artur Nozhenko on 04.06.2026.
//

import SwiftUI

struct CameraScreen: View {

    @StateObject private var faceDetector: FaceDetector
    @StateObject private var cameraManager: CameraSessionManager

    init() {
        let detector = FaceDetector()
        _faceDetector = StateObject(wrappedValue: detector)
        _cameraManager = StateObject(wrappedValue: CameraSessionManager(onSampleBuffer: detector.process))
    }

    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()

            FaceFrame()

            VStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }
        }
        .onAppear {
            cameraManager.start()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }

    private var statusColor: Color {
        guard faceDetector.isFaceDetected else { return .red }

        switch faceDetector.calibrationState {
        case .idle, .calibrating:
            return .orange
        case .calibrated:
            return faceDetector.eyesClosed ? .red : .green
        }
    }

    private var statusText: String {
        guard faceDetector.isFaceDetected else { return "No face" }

        switch faceDetector.calibrationState {
        case .idle:
            return "Calibrating…"
        case .calibrating(let progress):
            return "Calibrating… \(Int(progress * 100))%"
        case .calibrated:
            let perclos = String(format: "PERCLOS %.0f%%", faceDetector.perclos * 100)
            return faceDetector.eyesClosed
                ? "Eyes closed · \(perclos)"
                : String(format: "EAR %.2f · \(perclos)", faceDetector.eyeAspectRatio)
        }
    }
}

#Preview {
    CameraScreen()
}
