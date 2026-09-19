import SwiftData
import SwiftUI

// MARK: - The Wisdom Jar
//
// A note written on a good day, drawn on a hard one.
//
// The jar is drawn rather than modelled: a glass body with a real specular
// highlight, a lid, a cast shadow, and paper tickets that stack from the
// bottom. Behind it sits a living scene — gradient, a soft light source, and
// slow particles — which is where the depth comes from. That is the trade
// against a 3D model: this reads as a place rather than an object, costs one
// draw call instead of a scene graph, and still looks like the rest of Tether.
//
// THEME owns the scene. FEEL owns the accent. They never overlap, so the rose
// (Warm) accent sits cleanly on every backdrop without turning muddy.

struct WisdomJarView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JarNote.createdAt, order: .reverse) private var notes: [JarNote]
    @Query private var profiles: [UserProfile]

    @State private var theme = SceneManager.shared
    @State private var draft = ""
    @State private var shareThisNote = true
    @State private var drawn: JarNote?
    @State private var showThemes = false

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return profiles.first { $0.id == id }
    }

    /// Notes written by you. The jar shows your own pile — a note you shared
    /// is one *they* can draw, not a foreign object in your own jar.
    private var myNotes: [JarNote] { notes.filter { $0.authorID == profile.id } }
    private var sharedCount: Int { notes.filter(\.sharedWithPartner).count }
    private var privateCount: Int { notes.count - sharedCount }

    /// Nudges a note on a good day. The jar only works if it is full when it
    /// is needed, and "for a hard day" is too heavy a cue to build a habit on.
    private var showInvitation: Bool {
        guard let latest = notes.first?.createdAt else { return true }
        let days = Calendar.current.dateComponents([.day],
                                                   from: latest, to: Date()).day ?? 0
        return days >= 14
    }

    var body: some View {
        NavigationStack {
            ZStack {
                scene

                ScrollView {
                    VStack(spacing: TetherSpace.xl) {
                        if showInvitation { invitation }
                        jar
                        drawButton
                        composer
                        sharingSummary
                    }
                    .padding(TetherSpace.margin)
                    .readableFrame()
                    .padding(.bottom, TetherSpace.xxl)
                }
            }
            .navigationTitle("Wisdom Jar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showThemes = true
                    } label: {
                        Image(systemName: theme.theme.symbol)
                            .foregroundStyle(theme.theme.isDark ? .white : TetherColor.brand)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(theme.theme.isDark ? .white : TetherColor.brand)
                }
            }
            .toolbarBackground(theme.theme.isDark ? .hidden : .visible, for: .navigationBar)
            .sheet(item: $drawn) { note in
                JarNoteSheet(note: note,
                             author: authorName(note.authorID),
                             theme: theme.theme)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showThemes) {
                SceneSheet(theme: theme)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: Scene

    private var scene: some View {
        ZStack {
            LinearGradient(colors: theme.theme.backdrop,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            SceneBackdrop(theme: theme.theme)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: theme.raw)
    }

    // MARK: Invitation

    private var invitation: some View {
        HStack(alignment: .top, spacing: TetherSpace.s) {
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundStyle(theme.theme.glow)
            Text("Something worth keeping? The jar is only full on a hard day if you fill it on a good one.")
                .font(TetherType.caption)
                .foregroundStyle(theme.theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(TetherSpace.m)
        .background(.ultraThinMaterial.opacity(0.5),
                    in: RoundedRectangle(cornerRadius: TetherRadius.small, style: .continuous))
    }

    // MARK: Jar

    private let jarW: CGFloat = 158
    private let jarH: CGFloat = 244

    private var jar: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(theme.theme.isDark ? 0.42 : 0.14))
                .frame(width: 140, height: 16)
                .blur(radius: 8)
                .offset(y: jarH / 2 - 2)

            JarGlass()
                .fill(LinearGradient(
                    colors: theme.theme.isDark
                        ? [Color.white.opacity(0.20), Color.white.opacity(0.04),
                           Color.white.opacity(0.12)]
                        : [Color.white.opacity(0.72), TetherColor.brand.opacity(0.07),
                           Color.white.opacity(0.42)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))
                .frame(width: jarW, height: jarH)

            tickets

            Capsule()
                .fill(LinearGradient(
                    colors: [.white.opacity(theme.theme.isDark ? 0.42 : 0.80),
                             .white.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: 11, height: 96)
                .offset(x: -jarW / 2 + 26, y: 22)
                .blur(radius: 1.5)

            // Glass edge: white on dark scenes, accent on light ones. Using the
            // accent on a dark backdrop would double up with the lid glow.
            JarGlass()
                .stroke(Color.white.opacity(theme.theme.isDark ? 0.34 : 0.0), lineWidth: 1.5)
                .frame(width: jarW, height: jarH)
            JarGlass()
                .stroke(TetherColor.brand.opacity(theme.theme.isDark ? 0.0 : 0.22), lineWidth: 1.5)
                .frame(width: jarW, height: jarH)

            lid
        }
        .frame(height: jarH + 60)
        .accessibilityElement()
        .accessibilityLabel("Wisdom jar with \(myNotes.count) \(myNotes.count == 1 ? "note" : "notes")")
    }

    private var lid: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(LinearGradient(
                    colors: [TetherColor.brand.opacity(0.95),
                             TetherColor.brand.opacity(0.66)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: jarW * 0.60, height: 20)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.white.opacity(0.32))
                .frame(width: jarW * 0.48, height: 4)
                .offset(y: -4)
        }
        .shadow(color: TetherColor.brand.opacity(0.45), radius: 10)
        .offset(y: -jarH / 2 + 4)
    }

    private var tickets: some View {
        let visible = min(myNotes.count, 14)
        return ZStack(alignment: .bottom) {
            ForEach(0..<visible, id: \.self) { i in
                TicketShape()
                    .fill(paperFill(i))
                    .frame(width: 52, height: 34)
                    .overlay(TicketShape().stroke(Color.black.opacity(0.07), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
                    .rotationEffect(.degrees(seed(i, 0) * 30 - 15))
                    .offset(x: seed(i, 1) * 60 - 30, y: -CGFloat(i) * 9 - 34)
            }
        }
        .frame(width: jarW - 16, height: jarH - 60, alignment: .bottom)
        // Seats the pile inside the base. The stack is bottom-aligned in a
        // half-height frame, so its floor is at offset + (jarH-60)/2.
        .offset(y: jarH / 2 - 109)
        .animation(.spring(response: 0.5, dampingFraction: 0.72), value: myNotes.count)
    }

    private func seed(_ i: Int, _ salt: Int) -> Double {
        let x = sin(Double(i) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return x - x.rounded(.down)
    }

    private func paperFill(_ i: Int) -> LinearGradient {
        let tints: [Color] = [Color(hex: "FDF6E9"), Color(hex: "FBEFDC"),
                              Color(hex: "F7E7CE"), Color(hex: "FEF9F0")]
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
                    Text(myNotes.isEmpty ? "Nothing in the jar yet" : "Draw a note")
                        .font(TetherType.label)
                }
            }
            .tetherButton()
            .disabled(myNotes.isEmpty)

            if !myNotes.isEmpty {
                Text("You won't know which one you'll get.")
                    .font(TetherType.caption)
                    .foregroundStyle(theme.theme.faint)
            }
        }
    }

    private func draw() {
        guard !myNotes.isEmpty else { return }
        // Prefer notes never drawn, so a full jar keeps giving something new
        // rather than repeating the same three.
        let undrawn = myNotes.filter { $0.drawnCount == 0 }
        let pool = undrawn.isEmpty ? myNotes : undrawn
        guard let pick = pool.randomElement() else { return }
        pick.drawnCount += 1
        pick.lastDrawnAt = Date()
        try? ctx.save()
        TetherHaptics.success()
        drawn = pick
    }

    // MARK: Compose

    private var composer: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            Text("ADD TO THE JAR")
                .font(TetherType.micro)
                .tracking(1)
                .foregroundStyle(theme.theme.faint)

            Text("Something true, kind, or useful. For a hard day — theirs or yours.")
                .font(TetherType.caption)
                .foregroundStyle(theme.theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            TextField("Write a note…", text: $draft, axis: .vertical)
                .lineLimit(2...6)
                .tetherField()

            // Sharing is chosen at the moment of writing, never assumed
            // silently. Defaults on, because a jar nobody can see is a diary —
            // but a note can always be held back, and that must not feel like
            // a betrayal.
            if partner != nil {
                Button {
                    shareThisNote.toggle()
                    TetherHaptics.light()
                } label: {
                    HStack(spacing: TetherSpace.s) {
                        Image(systemName: shareThisNote ? "person.2.fill" : "lock.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(shareThisNote ? TetherColor.brand : theme.theme.faint)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(shareThisNote
                                 ? "Share with \(partner?.displayName ?? "them")"
                                 : "Just for me")
                                .font(TetherType.caption)
                                .foregroundStyle(theme.theme.ink)
                            Text(shareThisNote
                                 ? "They can draw this from the jar."
                                 : "Nobody else will ever see this one.")
                                .font(TetherType.micro)
                                .foregroundStyle(theme.theme.faint)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(theme.theme.faint)
                    }
                    .padding(TetherSpace.s)
                    .background(.ultraThinMaterial.opacity(0.45),
                                in: RoundedRectangle(cornerRadius: TetherRadius.small,
                                                     style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button("Fold it in") { add() }
                .tetherButton()
                .disabled(draft.trimmed.isEmpty)
                .opacity(draft.trimmed.isEmpty ? 0.45 : 1)
        }
        .padding(TetherSpace.m)
        .background(.ultraThinMaterial.opacity(0.35),
                    in: RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous))
    }

    /// Stated plainly, because a note's visibility should never be a mystery.
    @ViewBuilder
    private var sharingSummary: some View {
        if partner != nil, !notes.isEmpty {
            HStack(spacing: TetherSpace.s) {
                Image(systemName: "person.2")
                    .font(.system(size: 11))
                Text("\(sharedCount) shared · \(privateCount) private")
                    .font(TetherType.caption)
                Spacer(minLength: 0)
                Text("\(myNotes.count) yours")
                    .font(TetherType.caption)
            }
            .foregroundStyle(theme.theme.faint)
        } else if !notes.isEmpty {
            Text("\(myNotes.count) \(myNotes.count == 1 ? "note" : "notes") in the jar")
                .font(TetherType.caption)
                .foregroundStyle(theme.theme.faint)
        }
    }

    private func add() {
        let text = draft.trimmed
        guard !text.isEmpty else { return }
        ctx.insert(JarNote(authorID: profile.id,
                           body: text,
                           sharedWithPartner: shareThisNote))
        try? ctx.save()
        draft = ""
        TetherHaptics.success()
    }

    private func authorName(_ id: UUID) -> String {
        if id == profile.id { return "You" }
        return partner?.displayName ?? "Your partner"
    }
}

// MARK: - Shapes

struct JarGlass: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard rect.width > 0, rect.height > 0 else { return p }

        let w = rect.width, h = rect.height
        // A jar, not a bag: a modest neck, then a long gradual shoulder into a
        // tall body. The shoulder is what reads as "jar".
        let neck = w * 0.54
        let neckH = h * 0.075
        let shoulder = h * 0.17

        p.move(to: CGPoint(x: (w - neck) / 2, y: 0))
        p.addLine(to: CGPoint(x: (w + neck) / 2, y: 0))
        p.addLine(to: CGPoint(x: (w + neck) / 2, y: neckH))
        p.addQuadCurve(to: CGPoint(x: w, y: neckH + shoulder),
                       control: CGPoint(x: w, y: neckH + shoulder * 0.2))
        p.addLine(to: CGPoint(x: w, y: h - w * 0.22))
        p.addQuadCurve(to: CGPoint(x: w - w * 0.22, y: h),
                       control: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: w * 0.22, y: h))
        p.addQuadCurve(to: CGPoint(x: 0, y: h - w * 0.22),
                       control: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: neckH + shoulder))
        p.addQuadCurve(to: CGPoint(x: (w - neck) / 2, y: neckH),
                       control: CGPoint(x: 0, y: neckH + shoulder * 0.2))
        p.closeSubpath()
        return p
    }
}

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

// MARK: - Theme picker

/// One row of the theme list, extracted as its own view.
///
/// Inlined, the gradient + overlay + conditional checkmark pushed this
/// expression past what the type-checker could resolve in reasonable time.
/// Naming it is the fix, and it reads better besides.
struct SceneRow: View {
    let option: AppScene
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: TetherSpace.m) {
                swatch

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)
                    Text(option.blurb)
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                }

                Spacer(minLength: 0)

                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TetherColor.brand)
                }
            }
            .padding(TetherSpace.s)
            .background(TetherColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                        style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var swatch: some View {
        ZStack {
            LinearGradient(colors: option.backdrop,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            Image(systemName: option.symbol)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SceneSheet: View {
    @Bindable var theme: SceneManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TetherSpace.m) {
                    Text("A place, not a setting. Pick whichever you would want to sit in. This changes the whole app.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(AppScene.allCases) { option in
                        SceneRow(option: option,
                                    selected: theme.theme == option) {
                            theme.raw = option.rawValue
                            TetherHaptics.light()
                        }
                    }
                }
                .padding(TetherSpace.margin)
            }
            .background { TetherBackdrop() }
            .navigationTitle("Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - The drawn note

struct JarNoteSheet: View {
    let note: JarNote
    let author: String
    let theme: AppScene
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.backdrop,
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            SceneBackdrop(theme: theme)

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
                        .foregroundStyle(theme.faint)
                    Spacer()
                    if !note.sharedWithPartner {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.faint)
                    }
                }

                Text("“\(note.body)”")
                    .font(.system(size: 21, weight: .medium, design: .serif))
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 2) {
                    // The name leads. The point of drawing a note is the
                    // person, not the text.
                    Text(author)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(TetherColor.brand)
                    Text(note.createdAt.formatted(date: .long, time: .omitted))
                        .font(TetherType.caption)
                        .foregroundStyle(theme.faint)
                }

                Spacer(minLength: 0)

                Button("Keep it for today") { dismiss() }
                    .tetherButton()
            }
            .padding(TetherSpace.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
