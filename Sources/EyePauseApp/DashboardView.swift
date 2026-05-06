import EyePauseCore
import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.text(.dashboard))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                dashboardCard(model.text(.now)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.stateText)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(model.nextBreakText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(model.meetingStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: model.text(.continuousWork), model.continuousWorkText))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                dashboardCard(model.text(.quickActions)) {
                    LazyVGrid(columns: actionColumns, spacing: 8) {
                        Button(model.text(.startBreakNow)) { model.startBreakNow() }
                        Button(model.text(.delayFiveMinutes)) { model.delayCurrentReminder() }
                            .disabled(!model.canDelayCurrentReminder)
                        Button(model.text(.focusOneHour)) { model.focusOneHour() }
                        Button(model.text(.pauseTenMinutes)) { model.pause(minutes: 10) }
                        Button(model.text(.pauseToday)) { model.pauseToday() }
                    }
                    .buttonStyle(.bordered)
                }

                dashboardCard(model.text(.statistics)) {
                    VStack(alignment: .leading, spacing: 10) {
                        metricRow(model.text(.completedToday), "\(model.stats.today.completedCount)")
                        metricRow(model.text(.skippedToday), "\(model.stats.today.skippedCount)")
                        metricRow(model.text(.meetingSuppressedToday), "\(model.stats.today.meetingSuppressedCount)")
                        metricRow(model.text(.completionRate), model.todayCompletionRateText)
                        metricRow(model.text(.sevenDayCompleted), "\(model.stats.sevenDayCompletedBreakCount)")
                        metricRow(model.text(.sevenDayAttempted), "\(model.stats.sevenDayAttemptedBreakCount)")
                    }
                }

                dashboardCard(model.text(.breakPlan)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(model.longBreakProgressText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        ProgressView(value: model.longBreakProgressFraction)
                        Text(model.text(.exerciseGuidance))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            dashboardCard(model.text(.systemNotes)) {
                VStack(alignment: .leading, spacing: 8) {
                    labeledNote(model.text(.notifications), model.notificationStatusText)
                    labeledNote(model.text(.meetingMode), model.text(.meetingModeExplanation))
                }
            }
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(minimum: 220), spacing: 12),
            GridItem(.flexible(minimum: 220), spacing: 12)
        ]
    }

    private var actionColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 90), spacing: 8),
            GridItem(.flexible(minimum: 90), spacing: 8)
        ]
    }

    private func dashboardCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(red: 0.16, green: 0.34, blue: 0.24))
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

    private func metricRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .font(.caption)
    }

    private func labeledNote(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(body)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
