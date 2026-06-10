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
                        .fill(faceDetector.isFaceDetected ? .green : .red)
                        .frame(width: 12, height: 12)

                    Text(faceDetector.isFaceDetected ? "Face detected" : "No face")
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
}

#Preview {
    CameraScreen()
}
