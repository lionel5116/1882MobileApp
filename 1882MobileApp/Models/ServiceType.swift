import SwiftUI

enum ServiceType: String, CaseIterable, Codable, Identifiable {
    case direct   = "Direct"
    case indirect = "Indirect"
    case onDemand = "On Demand"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .direct:   return HISDTheme.directColor
        case .indirect: return HISDTheme.indirectColor
        case .onDemand: return HISDTheme.onDemandColor
        }
    }
}
