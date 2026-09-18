import Foundation
import Speech
import AVFoundation
import Observation

/// On-device dictation for the daily prompt and the coach.
///
/// `requiresOnDeviceRecognition` is set deliberately. The daily prompt is the
/// most personal thing a person types in this app, and the privacy promise is
/// that it never leaves the device. Falling back to Apple's servers would break
/// that promise silently, so when on-device recognition is unavailable we say so
/// rather than quietly uploading.
@Observable
final class VoiceInput {

    static let shared = VoiceInput()

    var isRecording = false
    var transcript = ""
    var errorMessage: String?
    var level: Double = 0          // 0…1, drives the mic pulse

    private let engine = AVAudioEngine()
    private var recogniser: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private init() {}

    // MARK: - Availability

    var isAvailable: Bool {
        guard let r = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else { return false }
        return r.isAvailable
    }

    var supportsOnDevice: Bool {
        SFSpeechRecognizer(locale: Locale(identifier: "en-US"))?.supportsOnDeviceRecognition ?? false
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let speech = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speech == .authorized else {
            errorMessage = "Speech recognition is off. You can enable it in Settings."
            return false
        }
        let mic = await AVAudioApplication.requestRecordPermission()
        guard mic else {
            errorMessage = "Microphone access is off. You can enable it in Settings."
            return false
        }
        return true
    }

    // MARK: - Recording

    func start() async {
        guard !isRecording else { return }
        errorMessage = nil
        transcript = ""

        guard await requestPermission() else { return }

        guard let recogniser = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recogniser.isAvailable else {
            errorMessage = "Dictation is not available right now."
            return
        }
        self.recogniser = recogniser

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Could not start the microphone."
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recogniser.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            request.append(buffer)
            self?.updateLevel(from: buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            errorMessage = "Could not start recording."
            cleanup()
            return
        }

        isRecording = true

        task = recogniser.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in self.transcript = result.bestTranscription.formattedString }
            }
            if error != nil || (result?.isFinal ?? false) {
                Task { @MainActor in self.stop() }
            }
        }
    }

    func stop() {
        guard isRecording || task != nil else { return }
        cleanup()
        isRecording = false
        level = 0
    }

    func toggle() async {
        if isRecording { stop() } else { await start() }
    }

    /// Clears the transcript without touching the session.
    func reset() {
        transcript = ""
        errorMessage = nil
    }

    // MARK: - Internals

    private func cleanup() {
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func updateLevel(from buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }
        var sum: Float = 0
        for i in 0..<count { sum += channel[i] * channel[i] }
        let rms = sqrt(sum / Float(count))
        let normalised = min(max(Double(rms) * 14, 0), 1)
        Task { @MainActor in self.level = normalised }
    }
}
