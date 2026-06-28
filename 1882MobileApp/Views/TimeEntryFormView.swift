import SwiftUI

struct TimeEntryFormView: View {
    @StateObject private var vm: TimeEntryFormViewModel
    let onSaved: () -> Void

    init(onSaved: @escaping () -> Void = {}) {
        self.onSaved = onSaved
        _vm = StateObject(wrappedValue: TimeEntryFormViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                billingRuleBanner

                VStack(spacing: 0) {
                    formCard
                }

                if let hrs = durationSummary {
                    durationPreview(hrs)
                }

                actionButtons
            }
            .padding()
        }
        .background(HISDTheme.pageBackground)
        .navigationTitle(vm.isEditing ? "Edit Time Entry" : "Log Time Entry")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(vm.isLoading)
        .overlay {
            if vm.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onChange(of: vm.didSave) { _, saved in
            if saved {
                vm.reset()
                onSaved()
            }
        }
    }

    // MARK: - Subviews

    private var billingRuleBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(HISDTheme.primaryBlue)
            Text("**Billing Rule:** Time is recorded in 30-minute increments. Durations under 30 minutes are not allowed; durations are rounded up to the nearest 30-minute block. Rate: **$50.00/hr**")
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
        .padding(14)
        .background(Color(hex: "EBF4FF"))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(HISDTheme.primaryBlue.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var formCard: some View {
        CardView {
            VStack(spacing: 0) {
                fieldRow {
                    FormTextField(label: "Employee Name", placeholder: "Jane Doe", text: $vm.employeeName)
                }
                divider
                fieldRow {
                    FormTextField(label: "Employee ID", placeholder: "EMP-12345", text: $vm.employeeId)
                }
                divider
                fieldRow {
                    FormTextField(label: "Campus Name", placeholder: "Reagan High School", text: $vm.campusName)
                }
                divider
                fieldRow {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("Date of Service")
                        DatePicker("", selection: $vm.dateOfService, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                divider
                fieldRow {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("Service Type")
                        Picker("Service Type", selection: $vm.serviceType) {
                            Text("Select type...").tag(ServiceType?.none)
                            ForEach(ServiceType.allCases) { type in
                                HStack {
                                    Circle()
                                        .fill(type.color)
                                        .frame(width: 8, height: 8)
                                    Text(type.displayName)
                                }
                                .tag(ServiceType?.some(type))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(vm.serviceType?.color ?? .secondary)
                    }
                }
                divider
                fieldRow {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("Start Time")
                        DatePicker("", selection: $vm.startTime, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                }
                divider
                fieldRow {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("End Time")
                        DatePicker("", selection: $vm.endTime, in: vm.startTime..., displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                }
                divider
                fieldRow {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("Service Description")
                        TextEditor(text: $vm.serviceDesc)
                            .frame(minHeight: 90)
                            .overlay(
                                Group {
                                    if vm.serviceDesc.isEmpty {
                                        Text("Describe the services provided...")
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 8)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                }

                // Inline duration error
                if vm.startTime < vm.endTime && !vm.isValidDuration {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("Duration must be at least 30 minutes")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task { await vm.save() }
            } label: {
                Text(vm.isEditing ? "Update Time Entry" : "Save Time Entry")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(vm.canSave ? HISDTheme.primaryBlue : Color.gray.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!vm.canSave)

            Button {
                vm.reset()
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HISDTheme.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(HISDTheme.primaryBlue, lineWidth: 1.5)
                    )
            }
        }
    }

    private var durationSummary: String? {
        guard vm.endTime > vm.startTime && vm.isValidDuration else { return nil }
        return "\(vm.roundedHours.asHours) hrs billed · est. \(vm.estimatedCost.asCurrency)"
    }

    private func durationPreview(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .foregroundColor(HISDTheme.primaryBlue)
                .font(.caption)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(HISDTheme.primaryBlue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(HISDTheme.primaryBlue.opacity(0.08))
        .clipShape(Capsule())
    }

    private var divider: some View {
        Divider().padding(.horizontal, 16)
    }

    private func fieldRow<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
    }
}

// MARK: - Shared form text field

private struct FormTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
        }
    }
}
