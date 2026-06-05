//
//  PermissionScreen.swift
//  Safety-Drive-Assistant
//
//  Created by Artur Nozhenko on 02.06.2026.
//

import SwiftUI

struct PermissionScreen: View {
    
    @State private var isAlertPresented = false
    @Binding var isCameraPresented: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                
                Spacer()
                
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(Color.blue)
                    .font(.system(size: 80))
                
                VStack(spacing: 12) {
                    Text("Permissions required")
                        .foregroundStyle(Color.white)
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("App tracks driver face and position. It's required to accept camera and motion permissions.")
                        .foregroundStyle(Color.gray)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    getPermissionTypeCell(.camera)
                    getPermissionTypeCell(.motion)
                }
                .padding(.horizontal, 20)
                
                
                Spacer()
                Spacer()
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            
            VStack {
                Spacer()
                
                Button {
                    PermissionManager.requestAccess { status in
                        switch status {
                        case .authorized: isCameraPresented = true
                        case .denied: print("Denied")
                        case .notDetermined: print("Show alert")
                        }
                    }
                } label: {
                    Text("Accept permission")
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                       
                }
                
                Text("App doesn't store data about user and doesn't send any data to external server to analyze.")
                    .foregroundStyle(Color.gray)
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func getPermissionTypeCell(_ permissionType: PermissionType) -> some View {
        HStack {
            Image(systemName: permissionType.imageName)
                .foregroundStyle(Color.blue)
                .font(.system(size: 20))
            
            VStack(alignment: .leading) {
                Text(permissionType.title)
                    .foregroundStyle(Color.white)
                    .font(.system(size: 16, weight: .bold))
                
                Text(permissionType.description)
                    .foregroundStyle(Color.gray)
                    .font(.system(size: 12))
            }
            
            Spacer()
        }
        .padding(15)
        .background(Color.secondary.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    PermissionScreen(isCameraPresented: .constant(false))
}

private enum PermissionType {
    case camera
    case motion
    
    
    var imageName: String {
        switch self {
        case .camera: "camera"
        case .motion: "iphone.motion"
        }
    }
    
    var title: String {
        switch self {
        case .camera: "Camera"
        case .motion: "Motion"
        }
    }
    
    var description: String {
        switch self {
        case .camera: "Camera tracks driver's face to prevent sleeping and distracting on the road."
        case .motion: "Motion track shaking to prevent using the phone while driving."
        }
    }
}
