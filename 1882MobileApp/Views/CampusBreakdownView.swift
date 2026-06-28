import SwiftUI

struct CampusBreakdownView: View {
    let campuses: [DashboardSummary.CampusBreakdown]
    let maxCost: Double

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Hours & Cost by Campus")
                    .font(HISDTheme.sectionHeader())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                ForEach(0..<campuses.count, id: \.self) { index in
                    CampusRowView(campus: campuses[index], maxCost: maxCost)
                    if index < campuses.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
                Spacer(minLength: 16)
            }
        }
    }
}

private struct CampusRowView: View {
    let campus: DashboardSummary.CampusBreakdown
    let maxCost: Double

    var ratio: Double {
        guard maxCost > 0 else { return 0 }
        return min(campus.totalCostDouble / maxCost, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(campus.campusName)
                    .font(HISDTheme.campusName())
                Spacer()
                Text(campus.totalCostDouble.asCurrency)
                    .font(.system(size: 15, weight: .semibold))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HISDTheme.primaryBlue)
                        .frame(width: geo.size.width * ratio, height: 6)
                }
            }
            .frame(height: 6)

            Text("\(campus.totalHoursDouble.asHours) hrs · \(campus.entryCountInt) entries")
                .font(HISDTheme.caption())
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
