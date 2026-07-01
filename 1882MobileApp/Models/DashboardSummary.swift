import Foundation

nonisolated struct DashboardSummary: Codable {
    let totals: Totals
    let byCampus: [CampusBreakdown]
    let byServiceType: [ServiceTypeBreakdown]
    let recentEntries: [TimeEntry]

    var campusesServed: Int { byCampus.count }
    var maxCampusCost: Double { byCampus.map(\.totalCostDouble).max() ?? 1 }

    nonisolated struct Totals: Codable {
        let totalEntries: String   // quoted integer from Postgres
        let totalHours: String     // quoted numeric
        let totalCost: String      // quoted numeric

        var totalEntriesInt: Int    { Int(totalEntries) ?? 0 }
        var totalHoursDouble: Double { Double(totalHours) ?? 0 }
        var totalCostDouble: Double  { Double(totalCost) ?? 0 }

        enum CodingKeys: String, CodingKey {
            case totalEntries = "total_entries"
            case totalHours   = "total_hours"
            case totalCost    = "total_cost"
        }
    }

    nonisolated struct CampusBreakdown: Codable {
        let campusName: String
        let entryCount: String
        let totalHours: String
        let totalCost: String

        var entryCountInt: Int      { Int(entryCount) ?? 0 }
        var totalHoursDouble: Double { Double(totalHours) ?? 0 }
        var totalCostDouble: Double  { Double(totalCost) ?? 0 }

        enum CodingKeys: String, CodingKey {
            case campusName = "campus_name"
            case entryCount = "entry_count"
            case totalHours = "total_hours"
            case totalCost  = "total_cost"
        }
    }

    nonisolated struct ServiceTypeBreakdown: Codable {
        let serviceType: String
        let entryCount: String
        let totalHours: String
        let totalCost: String

        var entryCountInt: Int       { Int(entryCount) ?? 0 }
        var totalHoursDouble: Double  { Double(totalHours) ?? 0 }
        var totalCostDouble: Double   { Double(totalCost) ?? 0 }
        var serviceTypeEnum: ServiceType? { ServiceType(rawValue: serviceType) }

        enum CodingKeys: String, CodingKey {
            case serviceType = "service_type"
            case entryCount  = "entry_count"
            case totalHours  = "total_hours"
            case totalCost   = "total_cost"
        }
    }

    enum CodingKeys: String, CodingKey {
        case totals
        case byCampus      = "by_campus"
        case byServiceType = "by_service_type"
        case recentEntries = "recent_entries"
    }
}
