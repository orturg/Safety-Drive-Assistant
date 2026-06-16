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

//            VStack {
//                HStack(spacing: 8) {
//                    Circle()
//                        .fill(statusColor)
//                        .frame(width: 12, height: 12)
//
//                    Text(statusText)
//                        .font(.caption)
//                        .foregroundStyle(.white)
//
//                    Spacer()
//                }
//                .padding(.horizontal)
//                .padding(.top, 8)
//
//                Spacer()
//            }
            
            setupText

            if case .calibrated = faceDetector.calibrationState {
                VStack {
                    Text(statusText)
                        .font(.caption.monospaced())
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 8)

                    Spacer()
                }
            }
        }
        .onAppear {
            cameraManager.start()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }
    
    private var setupText: some View {
        VStack {
            switch faceDetector.calibrationState {
            case .idle:
                getIdlePanel()
            case .calibrating(let progress):
                getCalibrationView(progress: progress)
            case .calibrated:
                getCalibratedView()
            }
            
            
            Spacer()
        }
    }
    
    private func getIdlePanel() -> some View {
        var text = ""
        if !faceDetector.isFaceDetected {
            text = "Set your phone in front of your face"
        } else if !isFaceFramed {
            text = "Set your face inside the frame"
        } else {
            text = "Hold your face, we can start calibration"
        }
        
        return VStack {
            Text(text)
                .foregroundStyle(Color.white)
                .font(.system(size: 20, weight: .medium))
                .multilineTextAlignment(.center)
                .padding()
                .background(.gray.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
            
            if faceDetector.isFaceDetected && isFaceFramed {
                Button {
                    faceDetector.isCalibrationEnabled = true
                } label: {
                    Text("Start calibration")
                        .foregroundStyle(.white)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

            }
        }
        .padding(.horizontal, 20)
    }
    
    private func getCalibrationView(progress: Double) -> some View {
        VStack {
            
            Spacer()
            
            VStack {
                Text("Calibrating")
                
                ProgressView(value: progress)
                    .foregroundStyle(.white)
                    .progressViewStyle(.linear)
                
            }
            .padding()
            .background(.gray.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }
    
    func getCalibratedView() -> some View {
        VStack {
            Text("Everything is set up")
                .foregroundStyle(Color.white)
                .font(.system(size: 20, weight: .medium))
                .multilineTextAlignment(.center)
                .padding()
                .background(.gray.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
            
            Button {
                faceDetector.startTrip()
            } label: {
                Text("Start trip")
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

        }
        .padding(.horizontal, 20)
    }
    
    private var isFaceFramed: Bool {
        guard faceDetector.isFaceDetected else { return false }
        let bb = faceDetector.faceBoundingBox
        return (0.20...0.65).contains(Double(bb.width))
            && (0.35...0.65).contains(Double(bb.midX))
            && (0.35...0.80).contains(Double(bb.midY))
    }

    private var statusText: String {
        var flags = faceDetector.isTripActive ? " · TRIP" : ""
        if faceDetector.eyesClosed { flags += " · EYES" }
        if faceDetector.isHeadDown { flags += " · HEAD" }
        if let alert = faceDetector.alert {
            flags += " · \(alert.type == .critical ? "CRIT" : "WARN") \(alert.reason)"
        }

        return String(format: "EAR %.2f · pitch %.0f° · PERCLOS %.0f%%",
                      faceDetector.eyeAspectRatio,
                      faceDetector.headPitch,
                      faceDetector.perclos * 100) + flags
    }
}

#Preview {
    CameraScreen()
}
