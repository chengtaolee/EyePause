import EyePauseCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            DashboardView(model: model)

            Divider()

            Picker(model.text(.language), selection: Binding(
                get: { model.settings.language },
                set: { model.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }

            Picker(model.text(.reminderInterval), selection: Binding(
                get: { model.settings.interval },
                set: { model.setInterval($0) }
            )) {
                ForEach(ReminderInterval.allCases) { interval in
                    Text(interval.title(language: model.settings.language)).tag(interval)
                }
            }

            Picker(model.text(.exerciseDuration), selection: Binding(
                get: { model.settings.exerciseDuration },
                set: { model.setExerciseDuration($0) }
            )) {
                ForEach(ExerciseDuration.allCases) { duration in
                    Text(duration.title(language: model.settings.language)).tag(duration)
                }
            }

            Picker(model.text(.longBreakDuration), selection: Binding(
                get: { model.settings.longBreakDuration },
                set: { model.setLongBreakDuration($0) }
            )) {
                ForEach(LongBreakDuration.allCases) { duration in
                    Text(duration.title(language: model.settings.language)).tag(duration)
                }
            }

            Section(model.text(.startBreakShortcut)) {
                HStack {
                    Text(model.shortcutDisplayText())
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                    Button(model.text(.recordShortcut)) {
                        model.startRecordingShortcut()
                    }
                    Button(model.text(.clearShortcut)) {
                        model.clearStartBreakShortcut()
                    }
                }
                if model.isRecordingShortcut {
                    Text(model.text(.recordShortcut))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(model.text(.forcedMode), isOn: Binding(
                get: { model.settings.isForcedModeEnabled },
                set: { _ in model.toggleForcedMode() }
            ))

            Toggle(model.text(.launchAtLogin), isOn: Binding(
                get: { model.settings.launchAtLoginEnabled },
                set: { model.setLaunchAtLogin($0) }
            ))
            if let launchAtLoginError = model.launchAtLoginError {
                Text(launchAtLoginError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Section(model.text(.statistics)) {
                LabeledContent(model.text(.completedToday), value: "\(model.stats.today.completedCount)")
                LabeledContent(model.text(.skippedToday), value: "\(model.stats.today.skippedCount)")
                LabeledContent(model.text(.meetingSuppressedToday), value: "\(model.stats.today.meetingSuppressedCount)")
                LabeledContent(String(format: model.text(.continuousWork), ""), value: model.continuousWorkText)
            }

            Section(model.text(.privacy)) {
                Text(model.text(.privacyBody))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
    }
}
