//
//  CameraScreen.swift
//  Safety-Drive-Assistant
//
//  Created by Artur Nozhenko on 04.06.2026.
//

import SwiftUI

struct CameraScreen: View {
    
    @StateObject private var cameraManager = CameraSessionManager()
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            FaceFrame()
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
