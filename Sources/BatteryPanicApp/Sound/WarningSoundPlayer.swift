import AppKit

protocol WarningSoundPlaying: AnyObject {
    func playWarning(named soundName: String)
    func playLoopingWarning(named soundName: String)
    func stop()
}

final class WarningSoundPlayer: WarningSoundPlaying {
    private var activeSound: NSSound?
    private var repeatTimer: Timer?
    private let sirenTonePlayer = SirenTonePlayer()

    func playWarning(named soundName: String) {
        playWarning(named: soundName, looping: false)
    }

    func playLoopingWarning(named soundName: String) {
        playWarning(named: soundName, looping: true)
    }

    private func playWarning(named soundName: String, looping: Bool) {
        repeatTimer?.invalidate()
        repeatTimer = nil
        activeSound?.stop()
        let warningSound = WarningSound.sound(named: soundName)

        if warningSound.source == .siren {
            activeSound = nil
            sirenTonePlayer.play(looping: looping)
            return
        }

        sirenTonePlayer.stop()
        if let sound = NSSound(named: NSSound.Name(warningSound.name)) {
            activeSound = sound
            sound.loops = false
            sound.volume = 0.85
            sound.currentTime = 0
            sound.play()

            if looping {
                let interval = max(sound.duration, 0.7)
                repeatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self, weak sound] _ in
                    guard self?.activeSound === sound else { return }
                    sound?.stop()
                    sound?.currentTime = 0
                    sound?.play()
                }
            }
        } else {
            NSSound.beep()
        }
    }

    func stop() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        activeSound?.stop()
        activeSound = nil
        sirenTonePlayer.stop()
    }
}
