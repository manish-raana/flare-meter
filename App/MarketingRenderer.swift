#if DEBUG
import SwiftUI
import WidgetKit

/// Renders App Store screenshots and website images from the real views and sample data:
/// `FlareMeter.app/Contents/MacOS/FlareMeter --render-marketing <folder>` (Debug builds only). The app is sandboxed, so
/// `<folder>` must be inside its container; `scripts/render-marketing.sh` copies the images into `marketing/`.
@MainActor
enum MarketingRenderer {
    static func runIfRequested() {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--render-marketing"), i + 1 < args.count else { return }
        let folder = URL(fileURLWithPath: args[i + 1], isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for scheme in [ColorScheme.light, .dark] {
            let suffix = scheme == .dark ? "-dark" : ""
            write(widgetsShot.environment(\.colorScheme, scheme), "appstore-widgets\(suffix).png", folder, scale: 1)
            write(panelShot.environment(\.colorScheme, scheme), "appstore-menubar\(suffix).png", folder, scale: 1)
            write(widget(.systemLarge).environment(\.colorScheme, scheme), "widget-large\(suffix).png", folder)
            write(widget(.systemMedium).environment(\.colorScheme, scheme), "widget-medium\(suffix).png", folder)
            write(widget(.systemSmall).environment(\.colorScheme, scheme), "widget-small\(suffix).png", folder)
            write(panel.environment(\.colorScheme, scheme), "panel\(suffix).png", folder)
            write(readmeHero.environment(\.colorScheme, scheme), "readme-hero\(suffix).png", folder)
            write(readmeWidgets.environment(\.colorScheme, scheme), "readme-widgets\(suffix).png", folder)
            write(readmeAlerts.environment(\.colorScheme, scheme), "readme-alerts\(suffix).png", folder)
        }
        write(readmeThemes, "readme-themes.png", folder)
        exit(0)
    }

    // MARK: Pieces

    private static let entry = UsageEntry(date: Date(), snapshot: .sample, problem: nil, accountID: "")

    /// macOS widget sizes, in points.
    private static func size(_ family: WidgetFamily) -> CGSize {
        switch family {
        case .systemSmall: return CGSize(width: 170, height: 170)
        case .systemMedium: return CGSize(width: 364, height: 170)
        default: return CGSize(width: 364, height: 382)
        }
    }

    private static func widget(_ family: WidgetFamily) -> some View {
        WidgetCard { UsageWidgetView(entry: entry, familyOverride: family) }
            .frame(width: size(family).width, height: size(family).height)
    }

    private static var panel: some View {
        MenuBarPanel()
            .environment(UsageStore(preview: .sample))
            .background(PanelBackground())
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: App Store screenshots (2880 × 1800)

    private static var widgetsShot: some View {
        Canvas2880(title: "Your Cloudflare limits, on your desktop",
                   subtitle: "Workers, Durable Objects, KV, D1 and Workers AI against your plan, refreshed every 15 minutes.") {
            HStack(alignment: .top, spacing: 24) {
                widget(.systemLarge)
                VStack(alignment: .leading, spacing: 24) {
                    widget(.systemMedium)
                    widget(.systemSmall)
                }
            }
            .scaleEffect(2.2)
            .frame(width: 2200, height: 900)
        }
    }

    private static var panelShot: some View {
        Canvas2880(title: "One glance at the menu bar",
                   subtitle: "Your fullest limit's percentage is always visible. Click it for every metric.") {
            VStack(alignment: .trailing, spacing: 8) {
                FakeMenuBar()
                panel.shadow(color: .black.opacity(0.25), radius: 18, y: 8)
                    .padding(.trailing, 40)
            }
            .frame(width: 620)
            .scaleEffect(1.9)
            .frame(width: 1300, height: 1150)
        }
    }

    // MARK: README images (no headline: the README has its own)

    /// A desktop: the menu bar with the panel open below FlareMeter's item, and the large widget.
    private static var readmeHero: some View {
        VStack(spacing: 0) {
            FakeMenuBar(showsAppMenu: true)
            HStack(alignment: .top, spacing: 0) {
                widget(.systemLarge).padding(.top, 40)
                Spacer(minLength: 40)
                panel.shadow(color: .black.opacity(0.25), radius: 18, y: 8).padding(.top, 8)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 48)
        }
        .frame(width: 880)
        .background(Backdrop())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// The three widget sizes.
    private static var readmeWidgets: some View {
        HStack(alignment: .top, spacing: 24) {
            widget(.systemLarge)
            VStack(alignment: .leading, spacing: 24) {
                widget(.systemMedium)
                widget(.systemSmall)
            }
        }
        .padding(40)
        .background(Backdrop())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// Early-warning notifications, in the words `UsageAlerts` uses, below the menu bar where macOS shows them.
    private static var readmeAlerts: some View {
        VStack(spacing: 0) {
            FakeMenuBar(showsAppMenu: true)
            VStack(spacing: 10) {
                NotificationBanner(title: "Unusual spike in DO requests", time: "now",
                                   message: "About 200k an hour, 142× its rate over the last day. At this pace you'll reach the included 1.0M in 2h 56m.")
                NotificationBanner(title: "Estimated charges passed $10", time: "2h ago",
                                   message: "About $12.40 past your plan's included usage this month, by FlareMeter's estimate.")
                NotificationBanner(title: "Worker requests at 85% of today's limit", time: "Yesterday",
                                   message: "85k of 100k. The limit resets at 00:00 UTC, in 13h 45m.")
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 14)
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .frame(width: 880)
        .background(Backdrop())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// The panel in light and dark, side by side.
    private static var readmeThemes: some View {
        HStack(spacing: 0) {
            ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
                panel.shadow(color: .black.opacity(0.25), radius: 18, y: 8)
                    .padding(48)
                    .background(Backdrop())
                    .environment(\.colorScheme, scheme)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Output

    private static func write(_ view: some View, _ name: String, _ folder: URL, scale: CGFloat = 2) {
        let renderer = ImageRenderer(content: view.environment(\.rendersStatically, true))
        renderer.scale = scale
        guard let image = renderer.cgImage, let png = eightBitPNG(image) else {
            print("couldn't render \(name)")
            return
        }
        do {
            try png.write(to: folder.appendingPathComponent(name))
        } catch {
            print("couldn't write \(name): \(error.localizedDescription)")
            return
        }
        print("wrote \(name) \(image.width)×\(image.height)")
    }

    /// Views with shadows render at 16 bits per channel. 8-bit sRGB looks the same at a quarter of the size.
    private static func eightBitPNG(_ image: CGImage) -> Data? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return context.makeImage().flatMap { NSBitmapImageRep(cgImage: $0).representation(using: .png, properties: [:]) }
    }
}

/// A widget's rounded card, as the desktop draws it.
private struct WidgetCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(scheme == .dark ? Color(white: 0.16) : Color(white: 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct PanelBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View { scheme == .dark ? Color(white: 0.14) : Color(white: 0.97) }
}

/// The right end of a menu bar with FlareMeter's item.
private struct FakeMenuBar: View {
    @Environment(\.colorScheme) private var scheme
    /// Also draws the Apple menu and Finder's menus, for a bar as wide as the image.
    var showsAppMenu = false

    var body: some View {
        HStack(spacing: 16) {
            if showsAppMenu {
                Image(systemName: "apple.logo")
                Text("Finder").fontWeight(.bold)
                ForEach(["File", "Edit", "View", "Go", "Window", "Help"], id: \.self) { Text($0) }
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "cloud.fill")
                Text("36%").monospacedDigit()
            }
            .padding(.horizontal, 8).padding(.vertical, 2)
            .background(.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 5))
            Image(systemName: "wifi")
            Image(systemName: "battery.75percent")
            Text("Sat 10 Oct  12:24")
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(height: 26)
        .background(.black.opacity(0.18))
    }
}

/// A notification banner as macOS draws it: the app icon, a title, the time, and the message.
private struct NotificationBanner: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let time: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)).resizable().frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    Spacer(minLength: 8)
                    Text(time).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Text(message).font(.system(size: 13)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(width: 400, alignment: .leading)
        .background(scheme == .dark ? Color(white: 0.17) : Color(white: 0.97), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 14, y: 6)
    }
}

/// 2880 × 1800 (the Mac App Store's largest size): a warm gradient, a headline, and the content.
private struct Canvas2880<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 28) {
            Group {
                Text(title).font(.system(size: 104, weight: .bold, design: .rounded))
                Text(subtitle).font(.system(size: 46, weight: .medium)).opacity(0.85)
                    .multilineTextAlignment(.center).frame(maxWidth: 2200)
            }
            .foregroundStyle(.white)
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
        }
        .padding(.top, 150)
        .padding(.bottom, 80)
        .frame(width: 2880, height: 1800)
        .background(Backdrop())
    }
}

/// The warm gradient behind every marketing image.
private struct Backdrop: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(colors: scheme == .dark
                       ? [Color(red: 0.22, green: 0.10, blue: 0.05), Color(red: 0.08, green: 0.06, blue: 0.10)]
                       : [Color(red: 1.0, green: 0.62, blue: 0.25), Color(red: 0.93, green: 0.33, blue: 0.13)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
#endif
