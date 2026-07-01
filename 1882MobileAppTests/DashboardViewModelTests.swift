import Testing
import Foundation
@testable import _882MobileApp

/// Covers the dashboard's load and delete flows via a mocked API.
@MainActor
@Suite struct DashboardViewModelTests {

    @Test func loadPopulatesSummaryOnSuccess() async {
        let api = MockAPIService()
        api.dashboardSummaryResult = .success(.empty)
        let vm = DashboardViewModel(api: api)

        await vm.load()

        #expect(vm.summary != nil)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test func loadSetsErrorMessageOnAPIError() async {
        let api = MockAPIService()
        api.dashboardSummaryResult = .failure(APIError(message: "Boom"))
        let vm = DashboardViewModel(api: api)

        await vm.load()

        #expect(vm.summary == nil)
        #expect(vm.errorMessage == "Boom")
        #expect(vm.isLoading == false)
    }

    @Test func deleteEntryDeletesThenReloads() async {
        let api = MockAPIService()
        api.dashboardSummaryResult = .success(.empty)
        let vm = DashboardViewModel(api: api)

        await vm.deleteEntry(id: 5)

        #expect(api.deletedIDs == [5])
        #expect(api.dashboardSummaryCallCount == 1)   // reload happened
        #expect(vm.summary != nil)
        #expect(vm.errorMessage == nil)
    }

    @Test func deleteEntrySurfacesErrorAndSkipsReload() async {
        let api = MockAPIService()
        api.deleteResult = .failure(APIError(message: "Cannot delete"))
        let vm = DashboardViewModel(api: api)

        await vm.deleteEntry(id: 5)

        #expect(vm.errorMessage == "Cannot delete")
        #expect(api.dashboardSummaryCallCount == 0)   // no reload after failure
    }
}
