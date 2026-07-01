import Foundation
@testable import _882MobileApp

// MARK: - Mock API

/// In-memory `APIServiceProtocol` so the view models can be tested without networking.
/// Each endpoint returns a configurable `Result` and records how it was called.
@MainActor
final class MockAPIService: APIServiceProtocol {

    // Stubbed responses — override per test as needed.
    var dashboardSummaryResult: Result<DashboardSummary, Error> = .success(.empty)
    var timeEntriesResult: Result<[TimeEntry], Error> = .success([])
    var timeEntryResult: Result<TimeEntry, Error> = .success(.sample())
    var createResult: Result<TimeEntry, Error> = .success(.sample())
    var updateResult: Result<TimeEntry, Error> = .success(.sample())
    var deleteResult: Result<Void, Error> = .success(())

    // Recorded calls — assert against these to verify behavior.
    private(set) var dashboardSummaryCallCount = 0
    private(set) var deletedIDs: [Int] = []
    private(set) var createdRequests: [TimeEntryRequest] = []
    private(set) var updatedCalls: [(id: Int, request: TimeEntryRequest)] = []

    func getDashboardSummary() async throws -> DashboardSummary {
        dashboardSummaryCallCount += 1
        return try dashboardSummaryResult.get()
    }

    func getTimeEntries() async throws -> [TimeEntry] {
        try timeEntriesResult.get()
    }

    func getTimeEntry(id: Int) async throws -> TimeEntry {
        try timeEntryResult.get()
    }

    func createTimeEntry(_ request: TimeEntryRequest) async throws -> TimeEntry {
        createdRequests.append(request)
        return try createResult.get()
    }

    func updateTimeEntry(id: Int, _ request: TimeEntryRequest) async throws -> TimeEntry {
        updatedCalls.append((id, request))
        return try updateResult.get()
    }

    func deleteTimeEntry(id: Int) async throws {
        deletedIDs.append(id)
        try deleteResult.get()
    }
}

// MARK: - Fixtures

extension TimeEntry {
    /// A fully-populated entry for use in tests. Times span exactly one hour.
    static func sample(
        id: Int = 1,
        employeeName: String = "Jane Doe",
        serviceType: String = "Direct"
    ) -> TimeEntry {
        TimeEntry(
            id: id,
            employeeName: employeeName,
            employeeId: "E123",
            campusName: "Central High",
            dateOfService: "2026-06-30",
            serviceType: serviceType,
            serviceDesc: "Tutoring session",
            startTime: "2026-06-30T09:00:00Z",
            endTime: "2026-06-30T10:00:00Z",
            totalTime: "1.0",
            totalCost: "50.00",
            createdAt: "2026-06-30T09:00:00Z"
        )
    }
}

extension DashboardSummary {
    /// An empty summary — zero totals, no breakdowns.
    static var empty: DashboardSummary {
        DashboardSummary(
            totals: Totals(totalEntries: "0", totalHours: "0", totalCost: "0"),
            byCampus: [],
            byServiceType: [],
            recentEntries: []
        )
    }
}
