import Foundation

struct TimeEntry: Codable, Identifiable {
    let id: Int
    let employeeName: String
    let employeeId: String
    let campusName: String
    let dateOfService: String      // "yyyy-MM-dd"
    let serviceType: String
    let serviceDesc: String
    let startTime: String          // ISO-8601
    let endTime: String            // ISO-8601
    let totalTime: String          // Postgres NUMERIC comes back quoted
    let totalCost: String          // Postgres NUMERIC comes back quoted
    let createdAt: String

    // Convenience parsers — tolerates future backend fix emitting real numbers
    var totalTimeDouble: Double { Double(totalTime) ?? 0 }
    var totalCostDouble: Double { Double(totalCost) ?? 0 }
    var serviceTypeEnum: ServiceType? { ServiceType(rawValue: serviceType) }

    var dateOfServiceFormatted: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        let display = DateFormatter()
        display.dateStyle = .medium
        if let d = parser.date(from: dateOfService) {
            return display.string(from: d)
        }
        return dateOfService
    }

    enum CodingKeys: String, CodingKey {
        case id
        case employeeName  = "employee_name"
        case employeeId    = "employee_id"
        case campusName    = "campus_name"
        case dateOfService = "date_of_service"
        case serviceType   = "service_type"
        case serviceDesc   = "service_desc"
        case startTime     = "start_time"
        case endTime       = "end_time"
        case totalTime     = "total_time"
        case totalCost     = "total_cost"
        case createdAt     = "created_at"
    }
}
