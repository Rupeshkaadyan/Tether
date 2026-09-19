import SwiftData
import SwiftUI

// MARK: - The Wisdom Jar
//
// A note written on a good day, drawn on a hard one.
//
// The jar is drawn rather than modelled: a glass body with a real specular
// highlight, a lid, a cast shadow, and paper tickets that stack from the
// bottom as notes are added. It reads as a solid object without needing a 3D
// asset, and it matches the illustrated landscape the rest of the app uses.
//
// Deliberately usable alone. A jar you fill yourself is still a jar — and it
// is the one part of Tether that gets *better* with time even if nobody else
// ever joins.

struct WisdomJarView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JarNote.createdAt, order: .reverse) private var notes: [JarNote]
    @Query private var profiles: [UserProfile]

    @State private var draft = ""
    @State private var composing = false
    @State private var drawn: JarNote?
    @State private var rise = false

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return profiles.first { $0.id == id }
    }

    private func authorName(_ id: UUID) -> String {
        if id == profile.id { return "You" }
        return partner?.displayName ?? "Your partner"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TetherSpace.xl) {
                    jar
                    drawButton
                    composer
                    if !notes.isEmpty { countLine }
                }
                .padding(TetherSpace.margin)
                .readableFrame()
                .padding(.bottom, TetherSpace.xxl)
            }
            .background { TetherBackdrop() }
            .navigationTitle("Wisdom Jar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $drawn) { note in
                JarNoteSheet(note: note, author: authorName(note.authorID))
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: Jar

    /// Jar proportions, shared by the body, the tickets and the lid so nothing
    /// drifts out of register.
    private let jarW: CGFloat = 158
    private let jarH: CGFloat = 244

    private var jar: some View {
        ZStack {
            // Cast shadow, so the jar sits on a surface rather than floating.
            Ellipse()
                .fill(Color.black.opacity(0.14))
                .frame(width: 140, height: 16)
                .blur(radius: 8)
                .offset(y: jarH / 2 - 2)

            // Glass body
            JarGlass()
                .fill(LinearGradient(
                    colors: [
                        Color.white.opacity(0.72),
                        TetherColor.brand.opacity(0.07),
                        Color.white.opacity(0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))
                .frame(width: jarW, height: jarH)

            // Tickets, sitting on the base of the jar.
            tickets

            // Specular highlight — the detail that reads as glass.
            Capsule()
                .fill(LinearGradient(
                    colors: [.white.opacity(0.80), .white.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: 11, height: 96)
                .offset(x: -jarW / 2 + 26, y: 22)
                .blur(radius: 1.5)

            JarGlass()
                .stroke(TetherColor.brand.opacity(0.22), lineWidth: 1.5)
                .frame(width: jarW, height: jarH)

            lid
        }
        .frame(height: jarH + 60)
        .accessibilityElement()
        .accessibilityLabel("Wisdom jar with \(notes.count) \(notes.count == 1 ? "note" : "notes")")
    }

    /// Sits on the neck, overlapping the glass so it reads as a lid rather
    /// than a hat floating above.
    private var lid: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(LinearGradient(
                    colors: [TetherColor.brand.opacity(0.92),
                             TetherColor.brand.opacity(0.62)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: jarW * 0.60, height: 20)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.white.opacity(0.30))
                .frame(width: jarW * 0.48, height: 4)
                .offset(y: -4)
        }
        .offset(y: -jarH / 2 + 4)
    }

    /// Paper tickets, filling from the bottom. Capped so a full jar does not
    /// become a texture; past that the jar simply reads as full.
    private var tickets: some View {
        let visible = min(notes.count, 14)
        return ZStack(alignment: .bottom) {
            ForEach(0..<visible, id: \.self) { i in
                TicketShape()
                    .fill(paperFill(i))
                    .frame(width: 52, height: 34)
                    .overlay(
                        TicketShape()
                            .stroke(Color.black.opacity(0.07), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
                    .rotationEffect(.degrees(seed(i, 0) * 30 - 15))
                    .offset(x: seed(i, 1) * 60 - 30,
                            y: -CGFloat(i) * 9 - 34)
            }
        }
        .frame(width: jarW - 16, height: jarH - 60, alignment: .bottom)
        // Seats the pile on the inside of the base. The stack is bottom-aligned
        // in a frame half its height, so its floor sits at offset + (jarH-60)/2;
        // this puts that floor just above the jar's bottom curve instead of
        // hanging below it.
        .offset(y: jarH / 2 - 109)
        .animation(.spring(response: 0.5, dampingFraction: 0.72), value: notes.count)
    }

    /// A stable pseudo-random value per ticket, so the pile looks scattered but
    /// never re-shuffles on redraw.
    private func seed(_ i: Int, _ salt: Int) -> Double {
        let x = sin(Double(i) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return x - x.rounded(.down)
    }

    private func paperFill(_ i: Int) -> LinearGradient {
        let tints: [Color] = [
            Color(hex: "FDF6E9"), Color(hex: "FBEFDC"),
            Color(hex: "F7E7CE"), Color(hex: "FEF9F0")
        ]
        let c = tints[i % tints.count]
        return LinearGradient(colors: [c, c.opacity(0.86)],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: Draw

    private var drawButton: some View {
        VStack(spacing: TetherSpace.s) {
            Button {
                draw()
            } label: {
                HStack(spacing: TetherSpace.s) {
                    TetherHeroMark(width: 24, color: .white, sag: 3,
                                   lineWidth: 1.5, dotRadius: 2)
                    Text(notes.isEmpty ? "Nothing in the jar yet" : "Draw a note")
                        .font(TetherType.label)
                }
            }
            .tetherButton()
            .disabled(notes.isEmpty)

            if !notes.isEmpty {
                Text("You won't know which one you'll get.")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
            }
        }
    }

    private func draw() {
        guard !notes.isEmpty else { return }
        // Prefer notes that have not been drawn before, so a full jar keeps
        // giving something new rather than repeating the same three.
        let undrawn = notes.filter { $0.drawnCount == 0 }
        let pool = undrawn.isEmpty ? notes : undrawn
        guard let pick = pool.randomElement() else { return }
        pick.drawnCount += 1
        pick.lastDrawnAt = Date()
        try? ctx.save()
        TetherHaptics.success()
        drawn = pick
    }

    // MARK: Compose

    private var composer: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                Text("ADD TO THE JAR")
                    .font(TetherType.micro)
                    .tracking(1)
                    .foregroundStyle(TetherColor.faint)

                Text("Something true, kind, or useful. For a hard day — theirs or yours.")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
                    .fixedSize(horizontal: false, vertical: true)

                TextField("Write a note…", text: $draft, axis: .vertical)
                    .lineLimit(2...6)
                    .tetherField()

                Button("Fold it in") { add() }
                    .tetherButton()
                    .disabled(draft.trimmed.isEmpty)
                    .opacity(draft.trimmed.isEmpty ? 0.45 : 1)
            }
        }
    }

    private var countLine: some View {
        Text("\(notes.count) \(notes.count == 1 ? "note" : "notes") in the jar")
            .font(TetherType.caption)
            .foregroundStyle(TetherColor.faint)
    }

    private func add() {
        let text = draft.trimmed
        guard !text.isEmpty else { return }
        ctx.insert(JarNote(authorID: profile.id, body: text))
        try? ctx.save()
        draft = ""
        TetherHaptics.success()
    }
}

// MARK: - Shapes

/// A jar: rounded body, shoulders, a short neck.
struct JarGlass: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard rect.width > 0, rect.height > 0 else { return p }

        let w = rect.width, h = rect.height
        // A jar, not a bag: a modest neck, then a long gradual shoulder into a
        // tall body. The earlier 0.42 neck with a 0.10 shoulder made a squat
        // box — the shoulder is what reads as "jar".
        let neck = w * 0.54
        let neckH = h * 0.075
        let shoulder = h * 0.17

        p.move(to: CGPoint(x: (w - neck) / 2, y: 0))
        p.addLine(to: CGPoint(x: (w + neck) / 2, y: 0))
        p.addLine(to: CGPoint(x: (w + neck) / 2, y: neckH))
        p.addQuadCurve(
            to: CGPoint(x: w, y: neckH + shoulder),
            control: CGPoint(x: w, y: neckH + shoulder * 0.2))
        p.addLine(to: CGPoint(x: w, y: h - w * 0.22))
        p.addQuadCurve(
            to: CGPoint(x: w - w * 0.22, y: h),
            control: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: w * 0.22, y: h))
        p.addQuadCurve(
            to: CGPoint(x: 0, y: h - w * 0.22),
            control: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: neckH + shoulder))
        p.addQuadCurve(
            to: CGPoint(x: (w - neck) / 2, y: neckH),
            control: CGPoint(x: 0, y: neckH + shoulder * 0.2))
        p.closeSubpath()
        return p
    }
}

/// A folded slip of paper: a rectangle with two clipped corners.
struct TicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard rect.width > 0, rect.height > 0 else { return p }
        let cut = min(rect.width, rect.height) * 0.28
        p.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
        p.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        p.closeSubpath()
        return p
    }
}

// MARK: - The drawn note

struct JarNoteSheet: View {
    let note: JarNote
    let author: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: TetherSpace.l) {
            HStack(spacing: TetherSpace.s) {
                TicketShape()
                    .fill(LinearGradient(
                        colors: [Color(hex: "FDF6E9"), Color(hex: "F7E7CE")],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 34, height: 24)
                    .overlay(TicketShape().stroke(Color.black.opacity(0.07), lineWidth: 0.5))
                Text("FROM THE JAR")
                    .font(TetherType.micro)
                    .tracking(1.2)
                    .foregroundStyle(TetherColor.faint)
                Spacer()
            }

            Text("“\(note.body)”")
                .font(.system(size: 21, weight: .medium, design: .serif))
                .foregroundStyle(TetherColor.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 2) {
                Text(author)
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.brand)
                Text(note.createdAt.formatted(date: .long, time: .omitted))
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.faint)
            }

            Spacer(minLength: 0)

            Button("Keep it for today") { dismiss() }
                .tetherButton()
        }
        .padding(TetherSpace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { TetherBackdrop() }
    }
}
