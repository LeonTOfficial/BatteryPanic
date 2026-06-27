import AppKit
import AVFoundation
import Foundation

final class SirenTonePlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isPrepared = false
    private var playbackFormat: AVAudioFormat?

    func play(looping: Bool = false) {
        do {
            try prepareIfNeeded()
            guard let playbackFormat else {
                NSSound.beep()
                return
            }

            player.stop()
            let options: AVAudioPlayerNodeBufferOptions = looping ? [.loops, .interrupts] : .interrupts
            player.scheduleBuffer(makeSirenBuffer(format: playbackFormat), at: nil, options: options, completionHandler: nil)
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

        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44_100
        let channelCount = max(outputFormat.channelCount, AVAudioChannelCount(2))
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount)

        guard let format else {
            throw SirenToneError.couldNotCreateAudioFormat
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.volume = 0.88
        playbackFormat = format
        try engine.start()
        isPrepared = true
    }

    private func makeSirenBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let duration = 1.8
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData else { return buffer }

        var phase = 0.0
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let sweep = (sin(t * Double.pi * 2.0 * 1.4) + 1.0) / 2.0
            let frequency = 520.0 + (sweep * 560.0)
            phase += (2.0 * Double.pi * frequency) / sampleRate

            let attack = min(1.0, t / 0.05)
            let release = min(1.0, (duration - t) / 0.18)
            let envelope = max(0.0, min(attack, release))
            let harmonic = sin(phase * 1.995) * 0.20
            let pulseGate = 0.62 + (0.38 * pow((sin(t * Double.pi * 7.0) + 1.0) / 2.0, 1.8))
            let sample = Float((sin(phase) + harmonic) * 0.32 * envelope * pulseGate)

            for channelIndex in 0..<Int(format.channelCount) {
                channelData[channelIndex][frame] = sample
            }
        }

        return buffer
    }
}

private enum SirenToneError: Error {
    case couldNotCreateAudioFormat
}
