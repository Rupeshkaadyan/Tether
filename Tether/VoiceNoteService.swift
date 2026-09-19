import AVFoundation
import Foundation

/// Records and plays short voice notes.
///
/// Deliberately simple: one note at a time, AAC in a temporary file, handed
/// back as `Data` so it can live in SwiftData's external storage alongside the
/// photo. Nothing streams and nothing uploads.
@Observable
final class VoiceNoteService: NSObject {
    static let shared = VoiceNoteService()

    var isRecording = false
    var errorMessage: String?
    /// The id of the note currently playing, so only one plays at a time.
    var playingID: UUID?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var tempURL: URL?

    // MARK: Recording

    func toggleRecording() async {
        if isRecording {
            _ = stopRecording()
        } else {
            await startRecording()
        }
    }

    private func startRecording() async {
        guard await requestPermission() else {
            errorMessage = "Microphone access is off. Turn it on in Settings to record."
            return
        }
        errorMessage = nil

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("tether-note-\(UUID().uuidString).m4a")
        tempURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            isRecording = true
        } catch {
            errorMessage = "Could not start recording."
        }
    }

    /// Stops and returns the recorded bytes, or nil if nothing was captured.
    func stopRecording() -> Data? {
        recorder?.stop()
        recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        guard let url = tempURL else { return nil }
        defer {
            try? FileManager.default.removeItem(at: url)
            tempURL = nil
        }
        let data = try? Data(contentsOf: url)
        guard let data, data.count > 1_024 else { return nil }
        return data
    }

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: Playback

    func togglePlayback(_ data: Data, id: UUID) {
        if playingID == id {
            stopPlayback()
            return
        }
        stopPlayback()

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        do {
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            player?.play()
            playingID = id
        } catch {
            errorMessage = "Could not play that note."
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        playingID = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

extension VoiceNoteService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.playingID = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
