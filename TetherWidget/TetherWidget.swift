import SwiftUI
import WidgetKit

// MARK: - Tether widget
//
// A quiet presence on the home screen: the mark, the time of day, and one line
// in the app's own voice.
//
// ─────────────────────────────────────────────────────────────────────────────
// WHY THIS DOES NOT SHOW YOUR STREAK OR TODAY'S QUESTION
//
// Reading the journal from a widget requires an App Group, and App Groups are
// NOT available under free provisioning. Adding the entitlement would make the
// app fail to sign on a free account — breaking the build that currently works
// on device.
//
// So this widget carries its own small content and asks nothing of the app.
// When the paid account exists, add the App Group, point both targets at it,
// and this can show the real streak and the real prompt.
// ─────────────────────────────────────────────────────────────────────────────

private enum WidgetVoice {
    /// Rotating lines in the app's voice. Deliberately not questions — a
    /// question on the home screen is homework, and the app is not homework.
    static let lines = [
        "One minute is enough.",
        "You do not have to have anything to say.",
        "Small and often beats grand and rare.",
        "Say the true thing, not the right thing.",
        "You can start on your own.",
        "Nothing here is shared with anyone.",
        "A hard day is still a day you showed up.",
        "Curiosity is most of love.",
        "You are allowed to be a work in progress.",
        "The ordinary Tuesday is the whole thing.",
        "Being known takes repetition.",
        "Come as you are. That is the point.",
    ]

    static func line(for date: Date) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return lines[abs(day) % lines.count]
    }

    static func greeting(for date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Late one"
        }
    }
}

struct TetherEntry: TimelineEntry {
    let date: Date
    let line: String
    let greeting: String
}

struct TetherProvider: TimelineProvider {
    func placeholder(in context: Context) -> TetherEntry {
        TetherEntry(date: Date(),
                    line: WidgetVoice.lines[0],
                    greeting: "Good evening")
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (TetherEntry) -> Void) {
        completion(entry(for: Date()))
    }

    /// Refreshes every four hours — enough to move the greeting through the
    /// day without waking the widget more than it needs.
    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<TetherEntry>) -> Void) {
        let now = Date()
        let entries = (0..<4).compactMap { step -> TetherEntry? in
            guard let date = Calendar.current.date(byAdding: .hour,
                                                   value: step * 4,
                                                   to: now) else { return nil }
            return entry(for: date)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(for date: Date) -> TetherEntry {
        TetherEntry(date: date,
                    line: WidgetVoice.line(for: date),
                    greeting: WidgetVoice.greeting(for: date))
    }
}

// MARK: - Views

struct TetherWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TetherEntry

    var body: some View {
        switch family {
        case .systemSmall:  small
        default:            medium
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            mark(size: 26)
            Spacer(minLength: 0)
            Text(entry.line)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { backdrop }
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 14) {
            mark(size: 34)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.greeting.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.5))

                Text(entry.line)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Text("Open Tether")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { backdrop }
    }

    /// The same night-sky gradient the app's landscape uses, so the widget
    /// reads as a window onto the same world.
    private var backdrop: some View {
        LinearGradient(
            colors: [Color(red: 0.18, green: 0.14, blue: 0.34),
                     Color(red: 0.10, green: 0.08, blue: 0.20),
                     Color(red: 0.24, green: 0.14, blue: 0.26)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
    }

    /// A local copy of the mark. The widget cannot import the app's types, so
    /// this is drawn here rather than shared — the one piece of duplication
    /// the target boundary forces.
    private func mark(size: CGFloat) -> some View {
        Canvas { ctx, canvas in
            let w = canvas.width, h = canvas.height
            let sag = h * 0.18
            var path = Path()
            path.move(to: CGPoint(x: 0, y: h * 0.32))
            path.addQuadCurve(
                to: CGPoint(x: w, y: h * 0.32),
                control: CGPoint(x: w / 2, y: h * 0.32 + sag * 2))
            ctx.stroke(path,
                       with: .color(.white.opacity(0.95)),
                       style: StrokeStyle(lineWidth: max(2, size * 0.11),
                                          lineCap: .round))
            for x in [CGFloat(0), w] {
                ctx.fill(Path(ellipseIn: CGRect(x: x - size * 0.075,
                                                y: h * 0.32 - size * 0.075,
                                                width: size * 0.15,
                                                height: size * 0.15)),
                         with: .color(.white))
            }
        }
        .frame(width: size, height: size * 0.72)
    }
}

// MARK: - Widget

struct TetherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TetherWidget", provider: TetherProvider()) { entry in
            TetherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tether")
        .description("A quiet line, one minute a day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct TetherWidgetBundle: WidgetBundle {
    var body: some Widget {
        TetherWidget()
    }
}
