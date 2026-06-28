import SwiftUI

struct RecentEntriesListView: View {
    let entries: [TimeEntry]
    let onDelete: (Int) async -> Void

    private var visible: [TimeEntry] { Array(entries.prefix(10)) }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Recent Time Entries")
                        .font(HISDTheme.sectionHeader())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Showing \(visible.count) of \(entries.count)")
                        .font(HISDTheme.caption())
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ForEach(0..<visible.count, id: \.self) { index in
                    NavigationLink {
                        TimeEntryDetailView(entry: visible[index], onDelete: onDelete)
                    } label: {
                        TimeEntryRowView(entry: visible[index])
                    }
                    .buttonStyle(.plain)

                    if index < visible.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
                Spacer(minLength: 16)
            }
        }
    }
}

struct TimeEntryRowView: View {
    let entry: TimeEntry

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(entry.serviceType.serviceTypeColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.employeeName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text(entry.campusName)
                    .font(HISDTheme.caption())
                    .foregroundColor(.secondary)
                Text(entry.dateOfServiceFormatted)
                    .font(HISDTheme.caption())
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(entry.totalCostDouble.asCurrency)
                    .font(.system(size: 14, weight: .semibold))
                Text(entry.serviceType)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(entry.serviceType.serviceTypeColor.opacity(0.15))
                    .foregroundColor(entry.serviceType.serviceTypeColor)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Detail / Edit view

struct TimeEntryDetailView: View {
    let entry: TimeEntry
    let onDelete: (Int) async -> Void

    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Employee") {
                LabeledContent("Name", value: entry.employeeName)
                LabeledContent("ID", value: entry.employeeId)
            }
            Section("Service") {
                LabeledContent("Campus", value: entry.campusName)
                LabeledContent("Date", value: entry.dateOfServiceFormatted)
                LabeledContent("Type", value: entry.serviceType)
            }
            Section("Description") {
                Text(entry.serviceDesc)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            Section("Billing") {
                LabeledContent("Hours", value: "\(entry.totalTimeDouble.asHours) hrs")
                LabeledContent("Cost", value: entry.totalCostDouble.asCurrency)
            }
            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Entry", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Entry #\(entry.id)")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this time entry?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await onDelete(entry.id)
                    dismiss()
                }
            }
        }
    }
}
