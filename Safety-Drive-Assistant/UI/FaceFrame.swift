//
//  FaceFrame.swift
//  Safety-Drive-Assistant
//
//  Created by Artur Nozhenko on 04.06.2026.
//

import SwiftUI

struct FaceFrame: View {
    
    let padding: CGFloat = 20
    
    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(
                x: padding, y: geo.size.height * 0.2,
                width: geo.size.width - padding * 2,
                height: geo.size.height * 0.5)
            
            ZStack {
                Color.black.opacity(0.25)
                    .mask {
                        Rectangle()
                            .overlay {
                                RoundedRectangle(cornerRadius: 28)
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.midX, y: rect.midY)
                                    .blendMode(.destinationOut)
                            }
                    }
                    .compositingGroup()
                    
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

#Preview {
    FaceFrame()
}
