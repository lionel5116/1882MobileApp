import Testing
import Foundation
@testable import _882MobileApp

/// Covers the form view model's duration math, validation, and save/edit flows.
@MainActor
@Suite struct TimeEntryFormViewModelTests {

    // MARK: Helpers

    /// A form populated with everything needed for `canSave == true` (60-minute duration).
    private func makeValidViewModel(api: MockAPIService) -> TimeEntryFormViewModel {
        let vm = TimeEntryFormViewModel(api: api)
        vm.employeeName = "Jane"
        vm.employeeId = "E1"
        vm.campusName = "Central"
        vm.serviceType = .direct
        vm.serviceDesc = "Tutoring"
        vm.startTime = Date(timeIntervalSince1970: 0)
        vm.endTime = Date(timeIntervalSince1970: 3600)
        return vm
    }

    private func setDuration(_ vm: TimeEntryFormViewModel, minutes: Double) {
        vm.startTime = Date(timeIntervalSince1970: 0)
        vm.endTime = Date(timeIntervalSince1970: minutes * 60)
    }

    // MARK: Duration & cost

    @Test func roundsUpToNextHalfHourBlock() {
        let vm = TimeEntryFormViewModel(api: MockAPIService())

        setDuration(vm, minutes: 45)
        #expect(vm.durationMinutes == 45)
        #expect(vm.roundedHours == 1.0)   // ceil(45/30) * 0.5
        #expect(vm.estimatedCost == 50)

        setDuration(vm, minutes: 30)
        #expect(vm.roundedHours == 0.5)
        #expect(vm.estimatedCost == 25)

        setDuration(vm, minutes: 61)
        #expect(vm.roundedHours == 1.5) // ceil(61/30) = 3 blocks
    }

    @Test func roundedHoursIsZeroForNonPositiveDuration() {
        let vm = TimeEntryFormViewModel(api: MockAPIService())
        vm.startTime = Date(timeIntervalSince1970: 3600)
        vm.endTime = Date(timeIntervalSince1970: 0)   // end before start
        #expect(vm.roundedHours == 0)
        #expect(vm.estimatedCost == 0)
    }

    @Test func durationIsValidAtThirtyMinutesButNotBelow() {
        let vm = TimeEntryFormViewModel(api: MockAPIService())
        setDuration(vm, minutes: 30)
        #expect(vm.isValidDuration)
        setDuration(vm, minutes: 29)
        #expect(vm.isValidDuration == false)
    }

    // MARK: Validation

    @Test func canSaveRequiresEveryFieldAndValidDuration() {
        let vm = makeValidViewModel(api: MockAPIService())
        #expect(vm.canSave)

        vm.employeeName = ""
        #expect(vm.canSave == false)
        vm.employeeName = "Jane"

        vm.serviceType = nil
        #expect(vm.canSave == false)
        vm.serviceType = .direct

        setDuration(vm, minutes: 20)   // too short
        #expect(vm.canSave == false)
    }

    // MARK: Edit-mode population

    @Test func initWithEntryEntersEditModeAndPopulatesFields() {
        let entry = TimeEntry.sample(id: 99, employeeName: "Bob", serviceType: "Indirect")
        let vm = TimeEntryFormViewModel(api: MockAPIService(), entry: entry)

        #expect(vm.isEditing)
        #expect(vm.entryId == 99)
        #expect(vm.employeeName == "Bob")
        #expect(vm.campusName == "Central High")
        #expect(vm.serviceType == .indirect)
        #expect(vm.canSave)   // one-hour sample is valid
    }

    // MARK: Save

    @Test func saveCreatesEntryWhenValid() async {
        let api = MockAPIService()
        let vm = makeValidViewModel(api: api)

        await vm.save()

        #expect(api.createdRequests.count == 1)
        #expect(api.updatedCalls.isEmpty)
        #expect(api.createdRequests.first?.serviceType == "Direct")
        #expect(vm.didSave)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test func saveUpdatesEntryInEditMode() async {
        let api = MockAPIService()
        let vm = TimeEntryFormViewModel(api: api, entry: .sample(id: 42))
        vm.serviceDesc = "Updated description"

        await vm.save()

        #expect(api.updatedCalls.first?.id == 42)
        #expect(api.createdRequests.isEmpty)
        #expect(vm.didSave)
    }

    @Test func saveDoesNothingWhenInvalid() async {
        let api = MockAPIService()
        let vm = TimeEntryFormViewModel(api: api)   // all fields empty

        await vm.save()

        #expect(api.createdRequests.isEmpty)
        #expect(vm.didSave == false)
    }

    @Test func saveSurfacesAPIErrorMessage() async {
        let api = MockAPIService()
        api.createResult = .failure(APIError(message: "Server is down"))
        let vm = makeValidViewModel(api: api)

        await vm.save()

        #expect(vm.didSave == false)
        #expect(vm.errorMessage == "Server is down")
        #expect(vm.isLoading == false)
    }

    // MARK: Reset

    @Test func resetClearsFieldsAndEditState() {
        let vm = makeValidViewModel(api: MockAPIService())
        vm.entryId = 5
        vm.didSave = true

        vm.reset()

        #expect(vm.employeeName.isEmpty)
        #expect(vm.serviceDesc.isEmpty)
        #expect(vm.serviceType == nil)
        #expect(vm.entryId == nil)
        #expect(vm.isEditing == false)
        #expect(vm.didSave == false)
    }
}
