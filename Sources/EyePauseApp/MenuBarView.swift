import EyePauseCore
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("EyePause")
                    .font(.headline)
                Text(model.stateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(model.meetingStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button(model.text(.startBreakNow)) {
                model.startBreakNow()
                dismiss()
            }

            Menu("\(model.text(.reminderInterval)): \(model.settings.interval.title(language: model.settings.language))") {
                ForEach(ReminderInterval.allCases) { interval in
                    Button(interval.title(language: model.settings.language)) {
                        model.setInterval(interval)
                    }
                }
            }

            Button(model.text(.delayFiveMinutes)) {
                model.delayCurrentReminder()
                dismiss()
            }
            .disabled(!model.canDelayCurrentReminder)

            Menu(model.text(.pause)) {
                Button(model.text(.pauseTenMinutes)) { model.pause(minutes: 10); dismiss() }
                Button(model.text(.focusOneHour)) { model.focusOneHour(); dismiss() }
                Button(model.settings.language.minutesText(30)) { model.pause(minutes: 30); dismiss() }
                Button(model.settings.language.minutesText(60)) { model.pause(minutes: 60); dismiss() }
                Button(model.settings.language.minutesText(90)) { model.pause(minutes: 90); dismiss() }
                Divider()
                Button(model.text(.pauseToday)) { model.pauseToday(); dismiss() }
            }

            Menu(model.text(.meetingMode)) {
                Button(model.settings.language.minutesText(30)) { model.setManualMeeting(minutes: 30); dismiss() }
                Button(model.settings.language.minutesText(60)) { model.setManualMeeting(minutes: 60); dismiss() }
                Button(model.settings.language.minutesText(90)) { model.setManualMeeting(minutes: 90); dismiss() }
                Divider()
                Button(model.text(.off)) { model.setManualMeeting(minutes: nil); dismiss() }
            }

            Toggle(model.text(.forcedMode), isOn: Binding(
                get: { model.settings.isForcedModeEnabled },
                set: { _ in model.toggleForcedMode() }
            ))

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(model.text(.today))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: model.text(.completedSkipped), model.stats.today.completedCount, model.stats.today.skippedCount))
                    .font(.caption)
                Text(String(format: model.text(.meetingSuppressed), model.stats.today.meetingSuppressedCount))
                    .font(.caption)
                Text(String(format: model.text(.continuousWork), model.continuousWorkText))
                    .font(.caption)
            }

            Divider()

            Button(model.text(.settings)) {
                model.showSettings()
                dismiss()
            }

            Button(model.text(.quit)) {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
    }
}
