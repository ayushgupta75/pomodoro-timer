import AVFoundation

final class AmbientSoundService {
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    func play(_ type: AmbientSoundType) {
        stop()
        guard type != .none else { return }

        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let frameCount = AVAudioFrameCount(sampleRate * 30)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        fill(buffer: buffer, type: type)

        player.scheduleBuffer(buffer, at: nil, options: .loops)

        do {
            try engine.start()
            player.play()
            self.engine = engine
            self.playerNode = player
        } catch {
            // audio engine unavailable — fail silently
        }
    }

    func stop() {
        playerNode?.stop()
        engine?.stop()
        playerNode = nil
        engine = nil
    }

    private func fill(buffer: AVAudioPCMBuffer, type: AmbientSoundType) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)

        switch type {
        case .none:
            break

        case .whiteNoise:
            for i in 0..<count {
                data[i] = Float.random(in: -0.5...0.5)
            }

        case .pinkNoise:
            // Paul Kellet's pink noise approximation
            var b0: Float = 0, b1: Float = 0, b2: Float = 0
            var b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0
            for i in 0..<count {
                let w = Float.random(in: -1...1)
                b0 = 0.99886 * b0 + w * 0.0555179
                b1 = 0.99332 * b1 + w * 0.0750759
                b2 = 0.96900 * b2 + w * 0.1538520
                b3 = 0.86650 * b3 + w * 0.3104856
                b4 = 0.55000 * b4 + w * 0.5329522
                b5 = -0.7616 * b5 - w * 0.0168980
                let pink = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362) * 0.11
                b6 = w * 0.115926
                data[i] = pink
            }

        case .brownNoise:
            var lastOut: Float = 0
            for i in 0..<count {
                let w = Float.random(in: -1...1)
                lastOut = (lastOut + 0.02 * w) / 1.02
                data[i] = lastOut * 3.5
            }
        }
    }
}
