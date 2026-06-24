import AppKit

final class WarningSoundPlayer {
    private var activeSound: NSSound?
    private let sirenTonePlayer = SirenTonePlayer()

    func playWarning(named soundName: String) {
        activeSound?.stop()
        let warningSound = WarningSound.sound(named: soundName)

        if warningSound.source == .siren {
            activeSound = nil
            sirenTonePlayer.play()
            return
        }

        sirenTonePlayer.stop()
        if let sound = NSSound(named: NSSound.Name(warningSound.name)) {
            activeSound = sound
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
