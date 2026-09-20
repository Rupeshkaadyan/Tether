import AVFoundation
import SwiftData
import SwiftUI

/// One journal entry, as a preview you can actually see.
///
/// A photo entry looks like a photo. A voice note looks like sound. Everything
/// else shows the first line of what was written. An icon grid only ever told
/// you what TYPES of thing were in there — this shows you the things.
struct JournalThumb: View {
    let entry: JournalEntry

    private let size: CGFloat = 84

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let data = entry.photoData,
                   let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else if let audio = entry.voiceData {
                    waveform(audio)
                } else {
                    textPreview
                }
            }
            .frame(width: size, height: size)
            .background(TetherColor.surfaceSunken)
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium,
                                        style: .continuous))

            // A small badge for the two kinds that are not obvious from the
            // thumbnail alone.
            if entry.photoData != nil || entry.voiceData != nil {
                Image(systemName: entry.photoData != nil ? "photo" : "mic")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(.black.opacity(0.45), in: Circle())
                    .padding(6)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous)
                .strokeBorder(TetherColor.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(previewLabel)
    }

    private var textPreview: some View {
        Text(SecureContent.read(entry.body))
            .font(.system(size: 12))
            .foregroundStyle(TetherColor.text)
            .lineLimit(5)
            .multilineTextAlignment(.leading)
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// A bar chart of the audio's own levels, not a decorative fake.
    ///
    /// Reading real samples means the shape matches what you actually said,
    /// so two recordings never look identical.
    private func waveform(_ data: Data) -> some View {
        let bars = WaveformSampler.levels(from: data, count: 18)
        return HStack(alignment: .center, spacing: 2) {
            ForEach(Array(bars.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(TetherColor.brand.opacity(0.75))
                    // Floor keeps silent bars visible as a flat line rather
                    // than vanishing, which would read as missing data.
                    .frame(width: 2, height: max(3, level * (size - 24)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 8)
    }

    private var previewLabel: String {
        if entry.photoData != nil { return "Photo entry" }
        if entry.voiceData != nil { return "Voice entry" }
        return SecureContent.read(entry.body)
    }
}

/// Reads REAL peak levels out of recorded audio.
///
/// Decoding the actual samples means the shape matches what was said, so two
/// recordings never look identical. A decorative waveform would be cheaper and
/// would quietly lie about the content.
enum WaveformSampler {
    static func levels(from data: Data, count: Int) -> [CGFloat] {
        guard let levels = peaks(from: data, count: count) else {
            // Gentle curve rather than flat bars, so a file we cannot read
            // still looks like a waveform and not like missing data.
            return (0..<count).map { i in 0.25 + 0.2 * sin(CGFloat(i) * 0.7) }
        }
        return levels.map { CGFloat(max(0.04, min(1, $0))) }
    }

    /// Decodes the audio and returns one peak per bucket, normalised to 0…1.
    private static func peaks(from data: Data, count: Int) -> [Float]? {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")
        defer { try? FileManager.default.removeItem(at: tmp) }

        do {
            try data.write(to: tmp)
            let file = try AVAudioFile(forReading: tmp)
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)),
                  file.length > 0
            else { return nil }

            try file.read(into: buffer)
            guard let channel = buffer.floatChannelData?[0] else { return nil }

            let total = Int(buffer.frameLength)
            guard total > 0 else { return nil }

            let per = max(1, total / count)
            var out: [Float] = []
            out.reserveCapacity(count)

            for bucket in 0..<count {
                let start = bucket * per
                let end = min(start + per, total)
                guard start < end else { out.append(0); continue }
                var peak: Float = 0
                for i in start..<end {
                    let v = abs(channel[i])
                    if v > peak { peak = v }
                }
                out.append(peak)
            }

            // Normalise against the loudest bucket so quiet recordings still
            // show a shape rather than a flat line at the floor.
            let maxPeak = out.max() ?? 0
            guard maxPeak > 0 else { return out }
            return out.map { $0 / maxPeak }
        } catch {
            return nil
        }
    }
}
