import Testing
import Foundation
@testable import _882MobileApp

/// Decoding tests for the API models. The backend returns snake_case keys and
/// quotes numeric columns (Postgres NUMERIC), so these verify the CodingKeys
/// mappings and the `*Double` / `*Int` parsing helpers.
@Suite struct ModelTests {

    @Test func decodesTimeEntryFromSnakeCaseJSON() throws {
        let json = """
        {
          "id": 7,
          "employee_name": "Jane Doe",
          "employee_id": "E123",
          "campus_name": "Central High",
          "date_of_service": "2026-06-30",
          "service_type": "Direct",
          "service_desc": "Tutoring",
          "start_time": "2026-06-30T09:00:00Z",
          "end_time": "2026-06-30T10:30:00Z",
          "total_time": "1.50",
          "total_cost": "75.00",
          "created_at": "2026-06-30T09:00:00Z"
        }
        """
        let entry = try JSONDecoder().decode(TimeEntry.self, from: Data(json.utf8))

        #expect(entry.id == 7)
        #expect(entry.employeeName == "Jane Doe")
        #expect(entry.campusName == "Central High")
        #expect(entry.totalTimeDouble == 1.5)
        #expect(entry.totalCostDouble == 75.0)
        #expect(entry.serviceTypeEnum == .direct)
    }

    @Test func timeEntryToleratesNonNumericTotals() {
        // The convenience parsers must not crash on unexpected values.
        let entry = TimeEntry.sample()
        let broken = TimeEntry(
            id: entry.id, employeeName: entry.employeeName, employeeId: entry.employeeId,
            campusName: entry.campusName, dateOfService: entry.dateOfService,
            serviceType: "Mystery", serviceDesc: entry.serviceDesc,
            startTime: entry.startTime, endTime: entry.endTime,
            totalTime: "N/A", totalCost: "", createdAt: entry.createdAt
        )

        #expect(broken.totalTimeDouble == 0)
        #expect(broken.totalCostDouble == 0)
        #expect(broken.serviceTypeEnum == nil)
    }

    @Test func decodesDashboardSummaryWithNestedBreakdowns() throws {
        let json = """
        {
          "totals": { "total_entries": "12", "total_hours": "30.5", "total_cost": "1525.00" },
          "by_campus": [
            { "campus_name": "Central", "entry_count": "5", "total_hours": "10", "total_cost": "500" },
            { "campus_name": "North", "entry_count": "7", "total_hours": "20.5", "total_cost": "1025" }
          ],
          "by_service_type": [
            { "service_type": "Direct", "entry_count": "8", "total_hours": "20", "total_cost": "1000" }
          ],
          "recent_entries": []
        }
        """
        let summary = try JSONDecoder().decode(DashboardSummary.self, from: Data(json.utf8))

        #expect(summary.totals.totalEntriesInt == 12)
        #expect(summary.totals.totalHoursDouble == 30.5)
        #expect(summary.totals.totalCostDouble == 1525.0)
        #expect(summary.byCampus.count == 2)
        #expect(summary.campusesServed == 2)
        #expect(summary.maxCampusCost == 1025)
        #expect(summary.byServiceType.first?.serviceTypeEnum == .direct)
        #expect(summary.byServiceType.first?.entryCountInt == 8)
    }

    @Test func maxCampusCostDefaultsToOneWhenEmpty() {
        // Guards against divide-by-zero in the bar-width math on the dashboard.
        #expect(DashboardSummary.empty.maxCampusCost == 1)
        #expect(DashboardSummary.empty.campusesServed == 0)
    }

    @Test func serviceTypeRoundTripsRawValues() {
        #expect(ServiceType(rawValue: "Direct") == .direct)
        #expect(ServiceType(rawValue: "Indirect") == .indirect)
        #expect(ServiceType(rawValue: "On Demand") == .onDemand)
        #expect(ServiceType(rawValue: "Bogus") == nil)
        #expect(ServiceType.allCases.count == 3)
        #expect(ServiceType.onDemand.displayName == "On Demand")
    }
}
