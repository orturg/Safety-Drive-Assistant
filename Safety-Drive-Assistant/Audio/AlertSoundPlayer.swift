//
//  AlertSoundPlayer.swift
//  Safety-Drive-Assistant
//
//  Created by Illia Antypenko on 16.06.2026.
//

import Foundation
import AVFoundation
import Combine

final class AlertSoundPlayer: ObservableObject {

    private var isSessionConfigured = false

    private lazy var warningPlayer = makePlayer(
        data: makeTone(frequency: 880, duration: 0.18, volume: 0.8),
        loops: 0
    )

    private lazy var criticalPlayer = makePlayer(
        data: makeTone(frequency: 1000, duration: 0.25, volume: 1.0, trailingSilence: 0.12),
        loops: -1
    )

    func playWarning() {
        configureSessionIfNeeded()
        criticalPlayer?.stop()
        warningPlayer?.currentTime = 0
        warningPlayer?.play()
    }

    func startCritical() {
        configureSessionIfNeeded()
        guard criticalPlayer?.isPlaying == false else { return }
        warningPlayer?.stop()
        criticalPlayer?.currentTime = 0
        criticalPlayer?.play()
    }

    func stop() {
        warningPlayer?.stop()
        criticalPlayer?.stop()
    }

    private func configureSessionIfNeeded() {
        guard !isSessionConfigured else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.duckOthers])
        try? session.setActive(true)
        isSessionConfigured = true
    }

    private func makePlayer(data: Data, loops: Int) -> AVAudioPlayer? {
        guard let player = try? AVAudioPlayer(data: data) else { return nil }
        player.numberOfLoops = loops
        player.prepareToPlay()
        return player
    }

    private func makeTone(frequency: Double, duration: Double, volume: Double, trailingSilence: Double = 0) -> Data {
        let sampleRate = 44_100.0
        let toneCount = Int(duration * sampleRate)
        let silenceCount = Int(trailingSilence * sampleRate)
        let fade = min(Double(toneCount) / 2, sampleRate * 0.005)

        var samples = [Int16]()
        samples.reserveCapacity(toneCount + silenceCount)

        for i in 0..<toneCount {
            let envelope: Double
            if Double(i) < fade {
                envelope = Double(i) / fade
            } else if Double(i) > Double(toneCount) - fade {
                envelope = Double(toneCount - i) / fade
            } else {
                envelope = 1
            }

            let value = sin(2 * .pi * frequency * Double(i) / sampleRate) * volume * envelope
            samples.append(Int16(max(-32_767, min(32_767, value * 32_767))))
        }

        samples.append(contentsOf: repeatElement(0, count: silenceCount))
        return wavData(from: samples, sampleRate: Int(sampleRate))
    }

    private func wavData(from samples: [Int16], sampleRate: Int) -> Data {
        let bitsPerSample = 16
        let channels = 1
        let blockAlign = channels * bitsPerSample / 8
        let byteRate = sampleRate * blockAlign
        let dataSize = samples.count * blockAlign

        var data = Data()

        func append(_ string: String) { data.append(contentsOf: string.utf8) }
        func append(uint32 value: UInt32) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        func append(uint16 value: UInt16) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }

        append("RIFF")
        append(uint32: UInt32(36 + dataSize))
        append("WAVE")
        append("fmt ")
        append(uint32: 16)
        append(uint16: 1)
        append(uint16: UInt16(channels))
        append(uint32: UInt32(sampleRate))
        append(uint32: UInt32(byteRate))
        append(uint16: UInt16(blockAlign))
        append(uint16: UInt16(bitsPerSample))
        append("data")
        append(uint32: UInt32(dataSize))

        for sample in samples {
            withUnsafeBytes(of: sample.littleEndian) { data.append(contentsOf: $0) }
        }

        return data
    }
}
