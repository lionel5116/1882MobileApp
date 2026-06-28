import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = 0
    @State private var dashboardRefreshID = UUID()

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: Dashboard tab
            NavigationStack {
                DashboardView(refreshID: dashboardRefreshID, switchToForm: { selectedTab = 1 })
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { hisdNavToolbar }
                    .toolbarBackground(HISDTheme.navy, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }
            .tag(0)

            // MARK: Log Time Entry tab
            NavigationStack {
                TimeEntryFormView {
                    selectedTab = 0
                    dashboardRefreshID = UUID()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { hisdNavToolbar }
                .toolbarBackground(HISDTheme.navy, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .tabItem {
                Label("Log Time Entry", systemImage: "plus.circle.fill")
            }
            .tag(1)
        }
        .tint(HISDTheme.teal)
    }

    // MARK: - Shared nav header

    @ToolbarContentBuilder
    private var hisdNavToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HISDNavLogoView()
        }
        ToolbarItem(placement: .topBarTrailing) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("Innovation & Development")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                Text("TEC 328.0253")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    RootTabView()
}
