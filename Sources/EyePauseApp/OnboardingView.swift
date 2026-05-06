import EyePauseCore
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(model.text(.onboardingTitle))
                .font(.title2)
                .bold()

            Picker(model.text(.language), selection: Binding(
                get: { model.settings.language },
                set: { model.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.menu)

            Picker(model.text(.reminderInterval), selection: Binding(
                get: { model.settings.interval },
                set: { model.setInterval($0) }
            )) {
                ForEach(ReminderInterval.allCases) { interval in
                    Text(interval.title(language: model.settings.language)).tag(interval)
                }
            }
            .pickerStyle(.menu)

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

            VStack(alignment: .leading, spacing: 8) {
                Text(model.text(.notifications))
                    .font(.headline)
                Text(model.notificationStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(model.text(.onboardingEnableNotifications)) {
                    model.requestNotificationPermissionFromOnboarding()
                }
            }

            Spacer()

            Button(model.text(.onboardingComplete)) {
                model.completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(24)
        .frame(width: 460, height: 420)
    }
}
