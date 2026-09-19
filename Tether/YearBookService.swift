import UIKit

/// Renders a couple's entries into a printable PDF keepsake.
///
/// Deliberately plain typesetting — a serif-free, generous-margin document
/// rather than a designed magazine. The words are the point, and this has to
/// survive being printed on A4.
enum YearBook {

    private static let pageSize = CGSize(width: 595, height: 842)   // A4 at 72dpi
    private static let margin: CGFloat = 64

    /// Returns the URL of the rendered PDF, or nil if there was nothing to
    /// render or the render failed.
    static func makePDF(profile: UserProfile,
                        partner: UserProfile?,
                        entries: [JournalEntry]) -> URL? {
        let sorted = entries.sorted { $0.entryDate < $1.entryDate }
        guard !sorted.isEmpty else { return nil }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Tether Year Book.pdf")

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize)
        )

        do {
            try renderer.writePDF(to: url) { ctx in
                drawCover(ctx, profile: profile, partner: partner, entries: sorted)
                drawEntries(ctx, entries: sorted)
            }
            return url
        } catch {
            return nil
        }
    }

    // MARK: Cover

    private static func drawCover(_ ctx: UIGraphicsPDFRendererContext,
                                  profile: UserProfile,
                                  partner: UserProfile?,
                                  entries: [JournalEntry]) {
        ctx.beginPage()

        let ink = UIColor(red: 0.13, green: 0.11, blue: 0.20, alpha: 1)
        let muted = UIColor(red: 0.45, green: 0.42, blue: 0.50, alpha: 1)

        // A band of brand colour across the top.
        let band = UIBezierPath(rect: CGRect(x: 0, y: 0,
                                             width: pageSize.width, height: 12))
        UIColor(red: 0.42, green: 0.34, blue: 0.85, alpha: 1).setFill()
        band.fill()

        let title = "Tether"
        title.draw(at: CGPoint(x: margin, y: 150), withAttributes: [
            .font: UIFont.systemFont(ofSize: 40, weight: .bold),
            .foregroundColor: ink
        ])

        let names = partner == nil
            ? profile.displayName
            : "\(profile.displayName) & \(partner!.displayName)"
        names.draw(at: CGPoint(x: margin, y: 208), withAttributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: UIColor(red: 0.42, green: 0.34, blue: 0.85, alpha: 1)
        ])

        if let first = entries.first?.entryDate,
           let last = entries.last?.entryDate {
            let range = "\(first.formatted(date: .long, time: .omitted)) — \(last.formatted(date: .long, time: .omitted))"
            range.draw(at: CGPoint(x: margin, y: 244), withAttributes: [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: muted
            ])
        }

        let days = Set(entries.map { Calendar.current.startOfDay(for: $0.entryDate) }).count
        let summary = "\(entries.count) entries across \(days) days."
        summary.draw(at: CGPoint(x: margin, y: 282), withAttributes: [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: muted
        ])

        let footer = "Written on one device. Never uploaded."
        footer.draw(at: CGPoint(x: margin, y: pageSize.height - 96), withAttributes: [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: muted
        ])
    }

    // MARK: Entries

    private static func drawEntries(_ ctx: UIGraphicsPDFRendererContext,
                                    entries: [JournalEntry]) {
        let ink = UIColor(red: 0.13, green: 0.11, blue: 0.20, alpha: 1)
        let muted = UIColor(red: 0.50, green: 0.47, blue: 0.55, alpha: 1)
        let width = pageSize.width - margin * 2

        var y: CGFloat = margin
        var pageStarted = false

        func startPage() {
            ctx.beginPage()
            y = margin
            pageStarted = true
        }

        startPage()

        for entry in entries {
            let dateLine = "\(entry.entryDate.formatted(date: .long, time: .omitted))  ·  \(Mood.label(for: entry.mood))"
            let body = SecureContent.read(entry.body)

            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: muted,
                .kern: 0.6
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12.5),
                .foregroundColor: ink
            ]

            let dateHeight = dateLine.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin], context: nil).height
            let bodyHeight = body.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin], context: nil).height

            let needed = dateHeight + 6 + bodyHeight + 28
            if y + needed > pageSize.height - margin {
                startPage()
            }

            dateLine.draw(with: CGRect(x: margin, y: y, width: width, height: dateHeight),
                          options: [.usesLineFragmentOrigin], attributes: dateAttrs, context: nil)
            y += dateHeight + 6

            body.draw(with: CGRect(x: margin, y: y, width: width, height: bodyHeight),
                      options: [.usesLineFragmentOrigin], attributes: bodyAttrs, context: nil)
            y += bodyHeight + 12

            // A hairline between entries.
            let rule = UIBezierPath()
            rule.move(to: CGPoint(x: margin, y: y))
            rule.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
            rule.lineWidth = 0.5
            UIColor(white: 0.85, alpha: 1).setStroke()
            rule.stroke()

            y += 16
        }
        _ = pageStarted
    }
}
