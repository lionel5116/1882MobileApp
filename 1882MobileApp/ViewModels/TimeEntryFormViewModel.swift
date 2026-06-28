import Foundation
import Combine

@MainActor
final class TimeEntryFormViewModel: ObservableObject {
    // MARK: - Form fields
    @Published var employeeName = ""
    @Published var employeeId = ""
    @Published var campusName = ""
    @Published var dateOfService = Date()
    @Published var serviceType: ServiceType? = nil
    @Published var startTime = Date()
    @Published var endTime = Date().addingTimeInterval(3600)
    @Published var serviceDesc = ""

    // MARK: - State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didSave = false

    var entryId: Int?   // non-nil in edit mode
    var isEditing: Bool { entryId != nil }

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = LiveAPIService.shared, entry: TimeEntry? = nil) {
        self.api = api
        if let entry { populate(from: entry) }
    }

    // MARK: - Computed validation

    var durationMinutes: Double {
        endTime.timeIntervalSince(startTime) / 60
    }

    var roundedHours: Double {
        guard durationMinutes > 0 else { return 0 }
        let blocks = ceil(durationMinutes / 30)
        return blocks * 0.5
    }

    var estimatedCost: Double { roundedHours * 50 }

    var isValidDuration: Bool { durationMinutes >= 30 }

    var canSave: Bool {
        !employeeName.isEmpty &&
        !employeeId.isEmpty &&
        !campusName.isEmpty &&
        serviceType != nil &&
        !serviceDesc.isEmpty &&
        isValidDuration
    }

    // MARK: - Actions

    func save() async {
        guard canSave, let st = serviceType else { return }
        isLoading = true
        errorMessage = nil

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime]

        let request = TimeEntryRequest(
            employeeName: employeeName,
            employeeId: employeeId,
            campusName: campusName,
            dateOfService: dateFmt.string(from: dateOfService),
            serviceType: st.rawValue,
            serviceDesc: serviceDesc,
            startTime: isoFmt.string(from: startTime),
            endTime: isoFmt.string(from: endTime)
        )

        do {
            if let id = entryId {
                _ = try await api.updateTimeEntry(id: id, request)
            } else {
                _ = try await api.createTimeEntry(request)
            }
            didSave = true
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func reset() {
        employeeName = ""
        employeeId = ""
        campusName = ""
        dateOfService = Date()
        serviceType = nil
        startTime = Date()
        endTime = Date().addingTimeInterval(3600)
        serviceDesc = ""
        errorMessage = nil
        didSave = false
        entryId = nil
    }

    // MARK: - Private

    private func populate(from entry: TimeEntry) {
        employeeName = entry.employeeName
        employeeId = entry.employeeId
        campusName = entry.campusName
        serviceType = ServiceType(rawValue: entry.serviceType)
        serviceDesc = entry.serviceDesc
        entryId = entry.id

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        if let d = dateFmt.date(from: entry.dateOfService) { dateOfService = d }

        let isoFmt = ISO8601DateFormatter()
        if let s = isoFmt.date(from: entry.startTime) { startTime = s }
        if let e = isoFmt.date(from: entry.endTime)   { endTime = e }
    }
}
