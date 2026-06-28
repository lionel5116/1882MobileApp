import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var summary: DashboardSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = LiveAPIService.shared) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            summary = try await api.getDashboardSummary()
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteEntry(id: Int) async {
        do {
            try await api.deleteTimeEntry(id: id)
            await load()
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
