import SwiftUI

struct SettingsView: View {
    @Environment(AppearanceManager.self) private var appearance
    @Environment(NotificationManager.self) private var notifications
    @State private var showAddReminder = false
    @State private var newReminderDate = Date()
    @State private var deleteReminderTarget: ReminderTime?

    var body: some View {
        @Bindable var appearance = appearance

        List {
            // Appearance Section
            Section("Appearance") {
                Picker("Mode", selection: $appearance.selectedMode) {
                    ForEach(AppearanceManager.Mode.allCases, id: \.self) { mode in
                        Label(mode.label, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            // Notifications
            Section {
                Toggle(isOn: Binding(
                    get: { notifications.isEnabled },
                    set: { newValue in
                        if newValue {
                            notifications.requestPermissionAndEnable()
                        } else {
                            notifications.isEnabled = false
                        }
                    }
                )) {
                    Label("Expense Reminders", systemImage: "bell.badge")
                }

                if notifications.isEnabled {
                    ForEach(notifications.reminderTimes) { time in
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(AppTheme.accent)
                            Text(time.displayTime)
                            Spacer()
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteReminderTarget = time
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }

                    Button {
                        showAddReminder = true
                    } label: {
                        Label("Add Reminder", systemImage: "plus.circle")
                    }
                }
            } header: {
                Text("Reminders")
            } footer: {
                if notifications.isEnabled {
                    Text("Swipe left on a time to remove it.")
                }
            }

            // About
            Section("About") {
                LabeledContent("App", value: "Budgy by Darskie")
                LabeledContent("Version", value: "1.0.0")
            }

        }
        .navigationTitle("Settings")
        .alert("Delete Reminder?", isPresented: Binding(get: { deleteReminderTarget != nil }, set: { if !$0 { deleteReminderTarget = nil } }), presenting: deleteReminderTarget) { time in
            Button("Delete", role: .destructive) {
                notifications.removeReminder(time)
            }
        } message: { time in
            Text("Remove the \(time.displayTime) reminder?")
        }
        .sheet(isPresented: $showAddReminder) {
            addReminderSheet
        }
    }

    // MARK: - Add Reminder Sheet

    private var addReminderSheet: some View {
        NavigationStack {
            DatePicker("Time", selection: $newReminderDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .navigationTitle("Add Reminder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showAddReminder = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newReminderDate)
                            notifications.addReminder(hour: comps.hour ?? 8, minute: comps.minute ?? 0)
                            showAddReminder = false
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
        .presentationDetents([.medium])
    }

}
