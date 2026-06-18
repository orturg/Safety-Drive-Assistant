//
//  MotionService.swift
//  Safety-Drive-Assistant
//
//  Created by Artur Nozhenko on 18.06.2026.
//

import Foundation
import CoreMotion
import Combine

final class MotionService: ObservableObject {

    @Published private(set) var isPhoneInHand: Bool = false

    private let updateInterval: TimeInterval = 1.0 / 30.0

    private let gyroWindow: TimeInterval = 1.5
    private let gyroTrigger: Double = 0.8
    
    private let flatGravityZ: Double = 0.7
    private let flatSustained: TimeInterval = 1.5

    private let alertHold: TimeInterval = 2.5

    private let motion = CMMotionManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "motionQueue"
        q.qualityOfService = .userInitiated
        q.maxConcurrentOperationCount = 1
        return q
    }()

    private var gyroSamples: [(t: TimeInterval, contribution: Double)] = []
    private var lastTimestamp: TimeInterval?
    private var flatStartTime: TimeInterval?
    private var clearWorkItem: DispatchWorkItem?

    func start() {
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = updateInterval
        motion.startDeviceMotionUpdates(to: queue) { [weak self] data, _ in
            guard let data else { return }
            let omega = sqrt(
                data.rotationRate.x * data.rotationRate.x +
                data.rotationRate.y * data.rotationRate.y +
                data.rotationRate.z * data.rotationRate.z
            )
            let gz = data.gravity.z
            let t = data.timestamp
            DispatchQueue.main.async { [weak self] in
                self?.process(omega: omega, gravityZ: gz, timestamp: t)
            }
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        gyroSamples.removeAll()
        lastTimestamp = nil
        flatStartTime = nil
        clearWorkItem?.cancel()
        clearWorkItem = nil
        if isPhoneInHand { isPhoneInHand = false }
    }

    private func process(omega: Double, gravityZ: Double, timestamp t: TimeInterval) {
        let prevT = lastTimestamp
        lastTimestamp = t
        let dt = prevT.map { t - $0 } ?? 0
        guard dt >= 0, dt < 0.5 else { return }

        gyroSamples.append((t, omega * dt))
        let cutoff = t - gyroWindow
        while let head = gyroSamples.first, head.t < cutoff {
            gyroSamples.removeFirst()
        }
        let gyroIntegral = gyroSamples.reduce(0.0) { $0 + $1.contribution }

        var triggered = gyroIntegral > gyroTrigger

        if abs(gravityZ) > flatGravityZ {
            if flatStartTime == nil { flatStartTime = t }
            if let start = flatStartTime, t - start >= flatSustained {
                triggered = true
            }
        } else {
            flatStartTime = nil
        }

        if triggered { raiseAlert() }
    }

    private func raiseAlert() {
        if !isPhoneInHand { isPhoneInHand = true }

        clearWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.isPhoneInHand = false
            self?.clearWorkItem = nil
        }
        clearWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + alertHold, execute: work)
    }
}

