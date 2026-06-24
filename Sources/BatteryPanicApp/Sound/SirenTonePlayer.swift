import AppKit
import AVFoundation
import Foundation

final class SirenTonePlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isPrepared = false

    func play() {
        do {
            try prepareIfNeeded()
            player.stop()
            player.scheduleBuffer(makeSirenBuffer(), at: nil, options: .interrupts, completionHandler: nil)
            player.play()
        } catch {
            NSSound.beep()
        }
    }

    func stop() {
        player.stop()
    }

    private func prepareIfNeeded() throws {
        guard !isPrepared else {
            if !engine.isRunning {
                try engine.start()
            }
            return
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        try engine.start()
        isPrepared = true
    }

    private func makeSirenBuffer() -> AVAudioPCMBuffer {
        let sampleRate = 44_100.0
        let duration = 1.65
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let channel = buffer.floatChannelData?[0] else { return buffer }

        var phase = 0.0
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let sweep = (sin(t * Double.pi * 2.0 * 1.25) + 1.0) / 2.0
            let frequency = 540.0 + (sweep * 470.0)
            phase += (2.0 * Double.pi * frequency) / sampleRate

            let attack = min(1.0, t / 0.05)
            let release = min(1.0, (duration - t) / 0.14)
            let envelope = max(0.0, min(attack, release))
            let harmonic = sin(phase * 1.995) * 0.18
            channel[frame] = Float((sin(phase) + harmonic) * 0.34 * envelope)
        }

        return buffer
    }
}
