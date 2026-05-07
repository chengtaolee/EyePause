import EyePauseCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DashboardView(model: model)

                settingsSection {
                    settingRow(model.text(.language)) {
                        Picker(model.text(.language), selection: Binding(
                            get: { model.settings.language },
                            set: { model.setLanguage($0) }
                        )) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180, alignment: .leading)
                    }

                    settingRow(model.text(.reminderInterval)) {
                        Picker(model.text(.reminderInterval), selection: Binding(
                            get: { model.settings.interval },
                            set: { model.setInterval($0) }
                        )) {
                            ForEach(ReminderInterval.allCases) { interval in
                                Text(interval.title(language: model.settings.language)).tag(interval)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180, alignment: .leading)
                    }

                    settingRow(model.text(.exerciseDuration)) {
                        Picker(model.text(.exerciseDuration), selection: Binding(
                            get: { model.settings.exerciseDuration },
                            set: { model.setExerciseDuration($0) }
                        )) {
                            ForEach(ExerciseDuration.allCases) { duration in
                                Text(duration.title(language: model.settings.language)).tag(duration)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180, alignment: .leading)
                    }

                    settingRow(model.text(.longBreakDuration)) {
                        Picker(model.text(.longBreakDuration), selection: Binding(
                            get: { model.settings.longBreakDuration },
                            set: { model.setLongBreakDuration($0) }
                        )) {
                            ForEach(LongBreakDuration.allCases) { duration in
                                Text(duration.title(language: model.settings.language)).tag(duration)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180, alignment: .leading)
                    }

                    settingRow(model.text(.breakWindowPresentation)) {
                        Picker(model.text(.breakWindowPresentation), selection: Binding(
                            get: { model.settings.breakWindowPresentationMode },
                            set: { model.setBreakWindowPresentationMode($0) }
                        )) {
                            ForEach(BreakWindowPresentationMode.allCases) { mode in
                                Text(mode.title(language: model.settings.language)).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180, alignment: .leading)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        settingRow(model.text(.startBreakShortcut)) {
                            HStack(spacing: 10) {
                                Text(model.shortcutDisplayText())
                                    .font(.system(.body, design: .monospaced).weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 10)
                                    .frame(minWidth: 86, minHeight: 28, alignment: .leading)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                                Spacer(minLength: 12)

                                Button(model.text(.recordShortcut)) {
                                    model.startRecordingShortcut()
                                }
                                Button(model.text(.clearShortcut)) {
                                    model.clearStartBreakShortcut()
                                }
                                .disabled(!model.settings.startBreakShortcut.isConfigured)
                            }
                        }

                        if model.isRecordingShortcut {
                            Text(model.text(.recordingShortcutPrompt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 142)
                        }
                    }

                    Divider()

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

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.text(.privacy))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(model.text(.privacyBody))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private func settingRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 126, alignment: .trailing)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
