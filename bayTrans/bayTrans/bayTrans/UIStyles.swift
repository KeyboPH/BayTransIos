import SwiftUI

struct FormShell<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.scaled(.largeTitle).bold())
                        .foregroundStyle(BayTransColors.ink)
                    Text(subtitle)
                        .font(.scaled(.subheadline))
                        .foregroundStyle(BayTransColors.secondaryText)
                }
                content
            }
            .padding(18)
        }
        .background(BayTransColors.background.ignoresSafeArea())
    }
}

struct StatGrid: View {
    let items: [(String, String)]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0)
                        .font(.scaled(.caption))
                        .foregroundStyle(BayTransColors.secondaryText)
                    Text(item.1)
                        .font(.scaled(.title3).bold())
                        .foregroundStyle(BayTransColors.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(BayTransColors.field)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct BayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.scaled(.headline))
            .foregroundStyle(BayTransColors.paper)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(configuration.isPressed ? BayTransColors.accentDark : BayTransColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WideButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.scaled(.headline))
            .foregroundStyle(BayTransColors.paper)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? BayTransColors.accentDark : BayTransColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ChoiceButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isCorrect: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.scaled(.body))
            .foregroundStyle(BayTransColors.ink)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }

    private var backgroundColor: Color {
        guard isSelected else { return BayTransColors.field }
        return isCorrect ? .green.opacity(0.25) : .red.opacity(0.25)
    }
}

struct BayTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.scaled(.body))
            .padding(12)
            .background(BayTransColors.field)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct BayTransColors {
    private static func dynamicColor(light: UInt, dark: UInt, alpha: Double = 1.0) -> Color {
        Color(UIColor { traitCollection in
            let hex = traitCollection.userInterfaceStyle == .dark ? dark : light
            return UIColor(hex: hex, alpha: CGFloat(alpha))
        })
    }

    static var background: Color { dynamicColor(light: 0xF4F1E8, dark: 0x171914) }
    static var surface: Color { dynamicColor(light: 0xFFFFFF, dark: 0x262A21) }
    static var field: Color { dynamicColor(light: 0xFFFFFF, dark: 0x262A21) }
    static var ink: Color { dynamicColor(light: 0x1F1F1F, dark: 0xF4F1E8) }
    static var text: Color { dynamicColor(light: 0x1F1F1F, dark: 0xF4F1E8) }
    static var secondaryText: Color { dynamicColor(light: 0x5E5A4D, dark: 0xC9C4B2) }
    static var mutedText: Color { dynamicColor(light: 0x5E5A4D, dark: 0xC9C4B2) }
    static var border: Color { dynamicColor(light: 0xC8BDA4, dark: 0x66705D) }
    static var accent: Color { dynamicColor(light: 0x716647, dark: 0x596550) }
    static var primaryAccent: Color { dynamicColor(light: 0x716647, dark: 0x596550) }
    static var accentText: Color { dynamicColor(light: 0x1F1F1F, dark: 0xE7E1D5) }
    static var secondaryAccent: Color { dynamicColor(light: 0xC8BDA4, dark: 0xD6D0C3) }
    static var selection: Color { dynamicColor(light: 0xC8BDA4, dark: 0x596550) }
    static var paper: Color { dynamicColor(light: 0xF4F1E8, dark: 0xE7E1D5) }
    static var accentDark: Color { dynamicColor(light: 0x716647, dark: 0x596550) }
    static var nearBlack: Color { dynamicColor(light: 0x1F1F1F, dark: 0x171914) }
    static var charcoal: Color { dynamicColor(light: 0x5E5A4D, dark: 0xC9C4B2) }
}

extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(UIColor(hex: hex, alpha: CGFloat(alpha)))
    }
}

private struct FontScaleKey: EnvironmentKey {
    static let defaultValue = 1.0
}

extension EnvironmentValues {
    var fontScale: Double {
        get { self[FontScaleKey.self] }
        set { self[FontScaleKey.self] = newValue }
    }
}

extension Font {
    static func scaled(_ textStyle: Font.TextStyle) -> Font {
        .system(textStyle)
    }
}

func formatDuration(_ interval: TimeInterval) -> String {
    let seconds = Int(interval)
    return "\(seconds / 60):" + String(format: "%02d", seconds % 60)
}
