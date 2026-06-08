import AudioToolbox

struct SoundService {
    // Soft tick — plays every second below 7
    static func playTick() {
        AudioServicesPlaySystemSound(1104)  // "Tock" keyboard click
    }

    // Sharper tick — plays every second below 3
    static func playUrgentTick() {
        AudioServicesPlaySystemSound(1057)  // "Begin record" beep
    }

    // Chime — plays when session completes
    static func playComplete() {
        AudioServicesPlaySystemSound(1016)  // "Anticipate" chime
    }
}
