import SwiftUI

struct MetricCardView: View {
    let label: String
    let value: String
    let caption: String
    let accentColor: Color

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(HISDTheme.kpiLabel())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(value)
                    .font(HISDTheme.kpiValue())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(caption)
                    .font(HISDTheme.caption())
                    .foregroundColor(.secondary)

                Rectangle()
                    .fill(accentColor)
                    .frame(height: 3)
                    .clipShape(Capsule())
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    MetricCardView(
        label: "Total Hours Logged",
        value: "19.5",
        caption: "All time entries",
        accentColor: HISDTheme.accentBlue
    )
    .padding()
    .background(HISDTheme.pageBackground)
}
