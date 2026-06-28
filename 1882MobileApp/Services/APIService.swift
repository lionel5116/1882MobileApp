import Foundation

// MARK: - Request / Error types

struct TimeEntryRequest: Encodable {
    let employeeName: String
    let employeeId: String
    let campusName: String
    let dateOfService: String  // "yyyy-MM-dd"
    let serviceType: String
    let serviceDesc: String
    let startTime: String      // ISO-8601
    let endTime: String        // ISO-8601

    enum CodingKeys: String, CodingKey {
        case employeeName  = "employee_name"
        case employeeId    = "employee_id"
        case campusName    = "campus_name"
        case dateOfService = "date_of_service"
        case serviceType   = "service_type"
        case serviceDesc   = "service_desc"
        case startTime     = "start_time"
        case endTime       = "end_time"
    }
}

struct APIError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

private struct ErrorResponse: Codable {
    let error: String
}

// MARK: - Protocol
// All paths in one place so confirming PUT/DELETE/GET-by-id is a one-file change.

protocol APIServiceProtocol {
    func getDashboardSummary() async throws -> DashboardSummary
    func getTimeEntries() async throws -> [TimeEntry]
    func getTimeEntry(id: Int) async throws -> TimeEntry
    func createTimeEntry(_ request: TimeEntryRequest) async throws -> TimeEntry
    func updateTimeEntry(id: Int, _ request: TimeEntryRequest) async throws -> TimeEntry
    func deleteTimeEntry(id: Int) async throws
}

// MARK: - Live implementation

final class LiveAPIService: APIServiceProtocol {
    static let shared = LiveAPIService()

    // Simulator: localhost resolves to the Mac running Docker.
    // Physical device: replace with Mac LAN IP, e.g. http://192.168.x.x:8090
    // ATS note: localhost is exempt from ATS in the Simulator by default.
    // For a physical device add NSAppTransportSecurity → NSAllowsLocalNetworking = YES
    // to the target's Info tab in Xcode.
    static let baseURL = "http://localhost:8090/api"

    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: Endpoints

    func getDashboardSummary() async throws -> DashboardSummary {
        let url = try url("/dashboard-summary")
        let (data, response) = try await session.data(from: url)
        try validate(response, data: data)
        return try decoder.decode(DashboardSummary.self, from: data)
    }

    func getTimeEntries() async throws -> [TimeEntry] {
        let url = try url("/time-entries")
        let (data, response) = try await session.data(from: url)
        try validate(response, data: data)
        return try decoder.decode([TimeEntry].self, from: data)
    }

    func getTimeEntry(id: Int) async throws -> TimeEntry {
        let url = try url("/time-entries/\(id)")
        let (data, response) = try await session.data(from: url)
        try validate(response, data: data)
        return try decoder.decode(TimeEntry.self, from: data)
    }

    func createTimeEntry(_ request: TimeEntryRequest) async throws -> TimeEntry {
        var req = URLRequest(url: try url("/time-entries"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(request)
        let (data, response) = try await session.data(for: req)
        try validate(response, data: data)
        return try decoder.decode(TimeEntry.self, from: data)
    }

    func updateTimeEntry(id: Int, _ request: TimeEntryRequest) async throws -> TimeEntry {
        var req = URLRequest(url: try url("/time-entries/\(id)"))
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(request)
        let (data, response) = try await session.data(for: req)
        try validate(response, data: data)
        return try decoder.decode(TimeEntry.self, from: data)
    }

    func deleteTimeEntry(id: Int) async throws {
        var req = URLRequest(url: try url("/time-entries/\(id)"))
        req.httpMethod = "DELETE"
        let (data, response) = try await session.data(for: req)
        try validate(response, data: data)
    }

    // MARK: Helpers

    private func url(_ path: String) throws -> URL {
        guard let url = URL(string: Self.baseURL + path) else {
            throw APIError(message: "Invalid URL: \(path)")
        }
        return url
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard http.statusCode >= 200 && http.statusCode < 300 else {
            if let body = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError(message: body.error)
            }
            throw APIError(message: "Server error (\(http.statusCode))")
        }
    }
}
