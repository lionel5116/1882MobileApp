import SwiftUI

struct ServiceTypeBreakdownView: View {
    let items: [DashboardSummary.ServiceTypeBreakdown]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Breakdown by Service Type")
                    .font(HISDTheme.sectionHeader())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                ForEach(0..<items.count, id: \.self) { index in
                    ServiceTypeRowView(item: items[index])
                    if index < items.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
                Spacer(minLength: 16)
            }
        }
    }
}

private struct ServiceTypeRowView: View {
    let item: DashboardSummary.ServiceTypeBreakdown

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(item.serviceType.serviceTypeColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.serviceType)
                    .font(HISDTheme.campusName())
                Text("\(item.totalHoursDouble.asHours) hrs · \(item.entryCountInt) entries")
                    .font(HISDTheme.caption())
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(item.totalCostDouble.asCurrency)
                .font(.system(size: 15, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
