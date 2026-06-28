import SwiftUI

struct DashboardView: View {
    @StateObject private var vm: DashboardViewModel
    let refreshID: UUID
    let switchToForm: () -> Void

    init(refreshID: UUID, switchToForm: @escaping () -> Void) {
        self.refreshID = refreshID
        self.switchToForm = switchToForm
        _vm = StateObject(wrappedValue: DashboardViewModel())
    }

    //this is the main body of the view, which displays the dashboard content based on the state of the view model
    var body: some View {
        ScrollView {
            if let summary = vm.summary {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    kpiGrid(summary)
                    CampusBreakdownView(campuses: summary.byCampus, maxCost: summary.maxCampusCost)
                    ServiceTypeBreakdownView(items: summary.byServiceType)
                    RecentEntriesListView(entries: summary.recentEntries) { id in
                        await vm.deleteEntry(id: id)
                    }
                }
                .padding()
            } else if vm.isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 80)
            } else if let msg = vm.errorMessage {
                ContentUnavailableView {
                    Label("Could Not Load", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(msg)
                } actions: {
                    Button("Retry") {
                        Task { await vm.load() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 60)
            }
        }
        .background(HISDTheme.pageBackground)
        .refreshable { await vm.load() }
        .task(id: refreshID) { await vm.load() }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil && vm.summary != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    switchToForm()
                } label: {
                    Label("Log Time Entry", systemImage: "plus.circle.fill")
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Time Tracking Dashboard")
                .font(.title2.bold())
            Text("Innovation & Development · 1882 Schools")
                .font(.subheadline)
                .foregroundColor(HISDTheme.primaryBlue)
        }
    }

    private func kpiGrid(_ summary: DashboardSummary) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            MetricCardView(
                label: "Total Hours Logged",
                value: summary.totals.totalHoursDouble.asHours,
                caption: "All time entries",
                accentColor: HISDTheme.accentBlue
            )
            MetricCardView(
                label: "Total Amount to Bill HISD",
                value: summary.totals.totalCostDouble.asCurrency,
                caption: "Based on $50/hr rate",
                accentColor: HISDTheme.accentGreen
            )
            MetricCardView(
                label: "Total Entries",
                value: "\(summary.totals.totalEntriesInt)",
                caption: "Logged service records",
                accentColor: HISDTheme.accentAmber
            )
            MetricCardView(
                label: "Campuses Served",
                value: "\(summary.campusesServed)",
                caption: "Distinct 1882 schools",
                accentColor: HISDTheme.accentRed
            )
        }
    }
}
