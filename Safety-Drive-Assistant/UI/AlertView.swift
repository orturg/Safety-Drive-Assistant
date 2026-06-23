//
//  AlertView.swift
//  Safety-Drive-Assistant
//
//  Created by Artur Nozhenko on 03.06.2026.
//

import SwiftUI

struct AlertView: View {
    
    let alertType: AlertType
    let alertReason: AlertReason
    
    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: alertReason.imageName)
                .font(.system(size: 78))
                .symbolEffect(.bounce, options: .repeat(.continuous))
            
            VStack(spacing: 12) {
                Text(alertReason.title)
                    .font(.system(size: 42, weight: .bold))
                
                Text(alertReason.description)
                    .font(.system(size: 22))
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(alertType.bgColor)
    }
}

#Preview {
    AlertView(alertType: .warning, alertReason: .vehicleShake)
}

enum AlertType {
    case warning, critical
    
    var bgColor: Color {
        switch self {
        case .warning: .yellow
        case .critical: .red
        }
    }
    
    var title: String {
        switch self {
        case .warning: "Warning"
        case .critical: "Critical"
        }
    }
}

enum AlertReason: Equatable, Sendable {
    case eyesClosed
    case headDown
    case headTurned
    case nodding
    case faceLost
    case vehicleShake
    case unsafePhoneMotion

    var title: String {
        switch self {
        case .eyesClosed: "Eyes closed"
        case .headDown: "Head down"
        case .headTurned: "Eyes on the road"
        case .nodding: "Nodding off"
        case .faceLost: "Face not visible"
        case .vehicleShake: "Erratic motion"
        case .unsafePhoneMotion: "Secure the phone"
        }
    }

    var description: String {
        switch self {
        case .eyesClosed: "Open your eyes and watch the road!"
        case .headDown: "Lift your head and watch the road!"
        case .headTurned: "Look ahead and stay focused!"
        case .nodding: "You're falling asleep - pull over and rest!"
        case .faceLost: "Keep your face toward the camera!"
        case .vehicleShake: "Pull over if you feel unsafe!"
        case .unsafePhoneMotion: "Keep the phone steady and focus on the road!"
        }
    }
    
    var imageName: String {
        switch self {
        case .eyesClosed: "eye.slash.fill"
        case .headDown: "arrow.down.to.line"
        case .headTurned: "arrow.left.and.right"
        case .nodding: "moon.zzz.fill"
        case .faceLost: "person.crop.circle.badge.exclamationmark.fill"
        case .vehicleShake: "car.fill"
        case .unsafePhoneMotion: "iphone.slash"
        }
    }
}
