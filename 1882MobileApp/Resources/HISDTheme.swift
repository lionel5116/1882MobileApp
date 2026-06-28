import SwiftUI

enum HISDTheme {
    // MARK: - Colors
    static let navy        = Color(hex: "1B3A5C")
    static let teal        = Color(hex: "5BC8D6")
    static let pageBackground = Color(hex: "EEF1F5")
    static let primaryBlue = Color(hex: "1D5FBF")
    static let cardBackground = Color.white

    // KPI accent underline colors
    static let accentBlue   = Color(hex: "3B82F6")
    static let accentGreen  = Color(hex: "22C55E")
    static let accentAmber  = Color(hex: "F59E0B")
    static let accentRed    = Color(hex: "EF4444")

    // Service type indicator dots
    static let directColor    = Color(hex: "3B82F6")   // blue
    static let indirectColor  = Color(hex: "8B5CF6")   // purple
    static let onDemandColor  = Color(hex: "F59E0B")   // amber

    // MARK: - Fonts
    static func kpiValue() -> Font    { .system(size: 32, weight: .bold, design: .rounded) }
    static func kpiLabel() -> Font    { .system(size: 11, weight: .medium) }
    static func sectionHeader() -> Font { .system(size: 11, weight: .semibold).uppercaseSmallCaps() }
    static func campusName() -> Font  { .system(size: 15, weight: .medium) }
    static func caption() -> Font     { .system(size: 12, weight: .regular) }
}

// MARK: - Hex Color initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - HISD Logo in nav bar
struct HISDNavLogoView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "chart.bar.fill")
                .foregroundColor(HISDTheme.teal)
                .font(.system(size: 20, weight: .bold))
            VStack(alignment: .leading, spacing: 0) {
                Text("HISD")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text("1882 Cost Tracking")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(HISDTheme.teal)
            }
        }
    }
}

// MARK: - Card container
struct CardView<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .background(HISDTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Service type color helper
extension String {
    var serviceTypeColor: Color {
        switch self {
        case "Direct":    return HISDTheme.directColor
        case "Indirect":  return HISDTheme.indirectColor
        case "On Demand": return HISDTheme.onDemandColor
        default:          return .gray
        }
    }
}

// MARK: - Currency formatter
extension Double {
    var asCurrency: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: self)) ?? "$\(self)"
    }

    var asHours: String {
        String(format: "%.1f", self)
    }
}
