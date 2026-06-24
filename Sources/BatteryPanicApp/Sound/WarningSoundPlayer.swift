import AppKit

final class WarningSoundPlayer {
    private var activeSound: NSSound?

    func playWarning(named soundName: String) {
        activeSound?.stop()
        if let sound = NSSound(named: NSSound.Name(soundName)) {
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
    }
}
