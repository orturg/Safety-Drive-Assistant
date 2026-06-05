//
//  Safety_Drive_AssistantApp.swift
//  Safety-Drive-Assistant
//
//  Created by Artur Nozhenko on 02.06.2026.
//

import SwiftUI

@main
struct Safety_Drive_AssistantApp: App {
    
    @State private var isCameraPresented = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isCameraPresented {
                    CameraScreen()
                } else {
                    PermissionScreen(isCameraPresented: $isCameraPresented)
                }
            }
            .onAppear {
                isCameraPresented = PermissionManager.accessStatus() == .authorized
            }
        }
    }
}
