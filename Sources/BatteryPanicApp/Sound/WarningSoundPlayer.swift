import AppKit

final class WarningSoundPlayer {
    private var activeSound: NSSound?
    private let sirenTonePlayer = SirenTonePlayer()

    func playWarning(named soundName: String) {
        playWarning(named: soundName, looping: false)
    }

    func playLoopingWarning(named soundName: String) {
        playWarning(named: soundName, looping: true)
    }

    private func playWarning(named soundName: String, looping: Bool) {
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
            sound.loops = looping
            sound.volume = 0.85
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    func stop() {
        activeSound?.stop()
        activeSound = nil
        sirenTonePlayer.stop()
    }
}
