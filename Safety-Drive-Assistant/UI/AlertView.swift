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
    case faceLost
    case vehicleShake
    case phoneInHand

    var title: String {
        switch self {
        case .eyesClosed: "Eyes closed"
        case .headDown: "Head down"
        case .faceLost: "Face not visible"
        case .vehicleShake: "Erratic motion"
        case .phoneInHand: "Put down the phone"
        }
    }

    var description: String {
        switch self {
        case .eyesClosed: "Open your eyes and watch the road!"
        case .headDown: "Lift your head and watch the road!"
        case .faceLost: "Keep your face toward the camera!"
        case .vehicleShake: "Pull over if you feel unsafe!"
        case .phoneInHand: "Keep your hands on the wheel and eyes on the road!"
        }
    }
    
    var imageName: String {
        switch self {
        case .eyesClosed: "eye.slash.fill"
        case .headDown: "arrow.down.to.line"
        case .faceLost: "person.crop.circle.badge.exclamationmark.fill"
        case .vehicleShake: "car.fill"
        case .phoneInHand: "iphone.slash"
        }
    }
}
