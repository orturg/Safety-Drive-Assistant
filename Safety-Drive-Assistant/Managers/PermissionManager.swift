//
//  PermissionManager.swift
//  Safety-Drive-Assistant
//
//  Created by Artur Nozhenko on 02.06.2026.
//

import Foundation
import AVFoundation

enum RequestAccessStatus {
    case authorized
    case denied
    case notDetermined
}

enum PermissionManager {
    
    static func accessStatus() -> RequestAccessStatus {
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .denied: return .denied
        case .authorized: return .authorized
        }
    }
    
    static func requestAccess(completion: ((_ status: RequestAccessStatus) -> Void)?) {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    completion?(.authorized)
                }
            }
        } else {
            completion?(accessStatus())
        }
    }
}
