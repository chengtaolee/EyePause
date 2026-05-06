@preconcurrency import AppKit
import Combine
import EyePauseCore
import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: SettingsStore
    @Published var stats: StatsStore
    @Published private(set) var state: ReminderState
    @Published var currentExercise: Exercise?
    @Published var remainingExerciseSeconds: Int = 0
    @Published var skipInput: String = ""
    @Published var skipError: String?
    @Published var forcedSkipCode: String = ""
    @Published var isNotificationPermissionGranted = false
    @Published var launchAtLoginError: String?
    @Published var meetingStatusText = "Meeting mode off"
    @Published var isRecordingShortcut = false
    @Published private(set) var isLongBreakActive = false

    private var reminderEngine: ReminderEngine
    private var exerciseEngine = ExerciseEngine()
    private var skipGate = ForcedSkipGate()
    private let persistence: PersistenceStore
    private let widgetSnapshotStore = WidgetSnapshotStore()
    private let systemSignal = SystemMeetingSignal()
    private let shortcutController = ShortcutController()
    private let windowCoordinator = WindowCoordinator()
    private let notificationAdapter = NotificationCenterAdapter()
    private var longBreakPlanner = LongBreakPlanner()
    private var timer: Timer?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var currentBreakIsLong = false
    private var needsSave = false

    private static let staleContinuousWorkThreshold: TimeInterval = 60 * 60

    init(persistence: PersistenceStore = PersistenceStore()) {
        self.persistence = persistence
        let snapshot = persistence.load()
        var loadedStats = snapshot.stats
        let now = Date()
        let loadedDay = loadedStats.today.day
        loadedStats.rolloverIfNeeded(now: now)
        if loadedStats.today.day != loadedDay {
            self.needsSave = true
        }
        loadedStats.resetActiveWorkIfStale(now: now, threshold: Self.staleContinuousWorkThreshold)
        self.settings = snapshot.settings
        self.stats = loadedStats
        self.reminderEngine = ReminderEngine(
            now: now,
            settings: snapshot.settings,
            meetingDetector: MeetingDetector()
        )
        self.state = reminderEngine.state
        requestNotificationPermission()
        configureNotificationActions()
        installShortcutMonitors()
        installWorkspaceObservers()
        startTimer()
        publishWidgetSnapshot(now: now)
        showOnboardingIfNeeded()
    }

    deinit {
        MainActor.assumeIsolated {
            timer?.invalidate()
            shortcutController.invalidate()
            for observer in workspaceObservers {
                NSWorkspace.shared.notificationCenter.removeObserver(observer)
            }
        }
    }

    var menuBarSystemImage: String {
        switch state {
        case .active:
            return "eye"
        case .due:
            return "eye.circle"
        case .escalated:
            return "exclamationmark.circle"
        case .exerciseRunning:
            return "timer"
        case .paused:
            return "pause.circle"
        case .meetingSuppressed:
            return "video.circle"
        case .forced:
            return "lock.circle"
        }
    }

    var stateText: String {
        switch state {
        case .active:
            return text(.active)
        case .due:
            return text(.breakDue)
        case .escalated:
            return text(.breakOverdue)
        case .exerciseRunning:
            return text(.exerciseRunning)
        case .paused(let until):
            return "\(text(.pause)) \(until.formatted(date: .omitted, time: .shortened))"
        case .meetingSuppressed:
            return text(.meetingSuppression)
        case .forced:
            return text(.forcedBreak)
        }
    }

    var isForcedPresentation: Bool {
        state == .forced
    }

    var canDelayCurrentReminder: Bool {
        switch state {
        case .active, .due, .escalated:
            return currentExercise == nil
        case .exerciseRunning, .paused, .meetingSuppressed, .forced:
            return false
        }
    }

    var continuousWorkText: String {
        let minutes = max(0, Int(stats.continuousWorkDuration(now: Date()) / 60))
        return settings.language.minutesText(minutes)
    }

    var nextBreakText: String {
        switch state {
        case .due, .escalated, .forced:
            return text(.nextBreakDue)
        case .paused(let until):
            return String(format: text(.nextBreakIn), durationText(until.timeIntervalSince(Date())))
        case .meetingSuppressed:
            return text(.meetingSuppression)
        case .exerciseRunning:
            return text(.exerciseRunning)
        case .active:
            return String(format: text(.nextBreakIn), durationText(reminderEngine.nextReminderDate.timeIntervalSince(Date())))
        }
    }

    var notificationStatusText: String {
        if notificationAdapter.canUseUserNotifications {
            return isNotificationPermissionGranted ? text(.notificationGranted) : text(.notificationDenied)
        }
        return text(.notificationDevelopmentFallback)
    }

    var todayCompletionRateText: String {
        "\(stats.todayCompletionRatePercent)%"
    }

    var longBreakProgressText: String {
        let remaining = max(0, longBreakPlanner.shortBreaksBeforeLongBreak - longBreakPlanner.shortBreaksSinceLongBreak)
        if remaining == 0 {
            return text(.longBreakReady)
        }
        return String(format: text(.longBreakProgress), remaining)
    }

    var longBreakProgressFraction: Double {
        min(Double(longBreakPlanner.shortBreaksSinceLongBreak) / Double(longBreakPlanner.shortBreaksBeforeLongBreak), 1.0)
    }

    func setInterval(_ interval: ReminderInterval) {
        let now = Date()
        settings.interval = interval
        rebuildEngine(now: now)
        markDirty()
        publishWidgetSnapshot(now: now)
        save()
    }

    func setLanguage(_ language: AppLanguage) {
        settings.language = language
        markDirty()
        save()
        updateMeetingStatus(now: Date())
        configureNotificationActions()
    }

    func setExerciseDuration(_ duration: ExerciseDuration) {
        settings.exerciseDuration = duration
        markDirty()
        save()
    }

    func setLongBreakDuration(_ duration: LongBreakDuration) {
        settings.longBreakDuration = duration
        markDirty()
        save()
    }

    func toggleForcedMode() {
        settings.isForcedModeEnabled.toggle()
        reminderEngine.settings = settings
        markDirty()
        save()
    }

    func startBreakNow() {
        beginExercise(exerciseEngine.nextExercise())
    }

    func beginExercise(_ exercise: Exercise) {
        let now = Date()
        currentExercise = exercise
        currentBreakIsLong = longBreakPlanner.shouldStartLongBreak(now: now, stats: stats)
        isLongBreakActive = currentBreakIsLong
        remainingExerciseSeconds = currentBreakIsLong ? settings.breakDurationSeconds(isLongBreak: true) : exercise.durationSeconds
        skipInput = ""
        skipError = nil
        reminderEngine.beginExercise(exercise)
        state = reminderEngine.state
        presentReminderWindow()
        publishWidgetSnapshot(now: now)
    }

    func completeExercise() {
        guard let exercise = currentExercise else { return }
        let now = Date()
        reminderEngine.completeExercise(exercise, now: now, stats: &stats)
        currentExercise = nil
        remainingExerciseSeconds = 0
        state = reminderEngine.state
        if currentBreakIsLong {
            longBreakPlanner.recordCompletedLongBreak()
        } else {
            longBreakPlanner.recordCompletedShortBreak()
        }
        currentBreakIsLong = false
        isLongBreakActive = false
        dismissReminderWindow()
        markDirty()
        publishWidgetSnapshot(now: now)
        save()
    }

    func delayCurrentReminder() {
        guard canDelayCurrentReminder else { return }
        let now = Date()
        reminderEngine.delay(minutes: 5, now: now)
        state = reminderEngine.state
        dismissReminderWindow()
        publishWidgetSnapshot(now: now)
        save()
    }

    func pause(minutes: Int) {
        let now = Date()
        reminderEngine.pause(minutes: minutes, now: now)
        state = reminderEngine.state
        publishWidgetSnapshot(now: now)
        save()
    }

    func focusOneHour() {
        pause(minutes: 60)
    }

    func pauseToday() {
        let now = Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)) else {
            pause(minutes: 60)
            return
        }
        let minutes = max(1, Int(ceil(tomorrow.timeIntervalSince(now) / 60)))
        pause(minutes: minutes)
    }

    func setManualMeeting(minutes: Int?) {
        let now = Date()
        if let minutes {
            systemSignal.manualMeetingUntil = now.addingTimeInterval(TimeInterval(minutes * 60))
        } else {
            systemSignal.manualMeetingUntil = nil
        }
        updateMeetingStatus(now: now)

        guard currentExercise == nil else { return }
        let previousDay = stats.today.day
        reminderEngine.meetingDetector = systemSignal.meetingDetector(now: now)
        let events = reminderEngine.advance(to: now, stats: &stats)
        state = reminderEngine.state
        if state == .meetingSuppressed {
            dismissReminderWindow()
        }
        handle(events)
        markDirtyIfStatsChanged(events: events, previousDay: previousDay)
        publishWidgetSnapshot(now: now)
        save()
    }

    func skipForcedBreak() {
        guard isForcedPresentation else {
            let now = Date()
            reminderEngine.skip(now: now, stats: &stats)
            state = reminderEngine.state
            dismissReminderWindow()
            markDirty()
            publishWidgetSnapshot(now: now)
            save()
            return
        }

        if skipGate.canSkip(with: skipInput) {
            let now = Date()
            reminderEngine.skip(now: now, stats: &stats)
            state = reminderEngine.state
            skipInput = ""
            skipError = nil
            dismissReminderWindow()
            markDirty()
            publishWidgetSnapshot(now: now)
            save()
        } else {
            skipError = text(.codeMismatch)
        }
    }

    func skipCurrentReminderFromNotification() {
        guard currentExercise == nil else { return }

        if isForcedPresentation {
            presentReminderWindow()
            return
        }

        switch state {
        case .due, .escalated:
            let now = Date()
            reminderEngine.skip(now: now, stats: &stats)
            state = reminderEngine.state
            dismissReminderWindow()
            markDirty()
            publishWidgetSnapshot(now: now)
            save()
        case .active, .exerciseRunning, .paused, .meetingSuppressed, .forced:
            break
        }
    }

    func showSettings() {
        presentSettingsWindow()
    }

    func requestNotificationPermissionFromOnboarding() {
        requestNotificationPermission()
    }

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        markDirty()
        save()
        dismissOnboardingWindow()
    }

    func startRecordingShortcut() {
        shortcutController.isRecording = true
        isRecordingShortcut = true
    }

    func clearStartBreakShortcut() {
        settings.startBreakShortcut = KeyboardShortcutSetting()
        shortcutController.isRecording = false
        isRecordingShortcut = false
        markDirty()
        save()
    }

    func shortcutDisplayText() -> String {
        shortcutController.displayText(for: settings.startBreakShortcut, noShortcutText: text(.noShortcut))
    }

    func captureShortcut(from event: NSEvent) -> Bool {
        guard shortcutController.captureShortcut(from: event, settings: &settings) else { return false }
        isRecordingShortcut = shortcutController.isRecording
        markDirty()
        save()
        return true
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            settings.launchAtLoginEnabled = enabled
            launchAtLoginError = nil
            markDirty()
            save()
        } catch {
            settings.launchAtLoginEnabled = false
            launchAtLoginError = String(format: text(.launchAtLoginFailed), error.localizedDescription)
            NSLog("EyePause failed to set launch at login: \(error.localizedDescription)")
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick(now: Date())
            }
        }
    }

    private func installShortcutMonitors() {
        shortcutController.installMonitors(
            shortcut: { [weak self] in self?.settings.startBreakShortcut ?? KeyboardShortcutSetting() },
            canTrigger: { [weak self] in self?.canTriggerStartBreakShortcut ?? false },
            capture: { [weak self] event in self?.captureShortcut(from: event) ?? false },
            startBreak: { [weak self] in self?.startBreakNow() }
        )
    }

    private var canTriggerStartBreakShortcut: Bool {
        switch state {
        case .active, .due, .escalated:
            return currentExercise == nil
        case .exerciseRunning, .paused, .meetingSuppressed, .forced:
            return false
        }
    }

    private func installWorkspaceObservers() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        let names: [NSNotification.Name] = [
            NSWorkspace.willSleepNotification,
            NSWorkspace.didWakeNotification,
            NSWorkspace.sessionDidResignActiveNotification,
            NSWorkspace.sessionDidBecomeActiveNotification
        ]

        workspaceObservers = names.map { name in
            notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.handleSystemInterruption(now: Date())
                }
            }
        }
    }

    private func handleSystemInterruption(now: Date) {
        stats.recordSystemInterruption(now: now)
        markDirty()
        publishWidgetSnapshot(now: now)
        save()
    }

    private func tick(now: Date) {
        if currentExercise != nil {
            remainingExerciseSeconds = max(remainingExerciseSeconds - 1, 0)
            if remainingExerciseSeconds == 0 {
                completeExercise()
            }
            return
        }

        updateMeetingStatus(now: now)
        reminderEngine.settings = settings
        reminderEngine.meetingDetector = systemSignal.meetingDetector(now: now)
        let previousDay = stats.today.day
        let events = reminderEngine.advance(to: now, stats: &stats)
        state = reminderEngine.state
        handle(events)
        markDirtyIfStatsChanged(events: events, previousDay: previousDay)
        publishWidgetSnapshot(now: now)
        save()
    }

    private func handle(_ events: [ReminderEvent]) {
        for event in events {
            switch event {
            case .showNotification:
                showNotification()
            case .showProminentReminder(let forced):
                if forced {
                    skipGate = ForcedSkipGate()
                    forcedSkipCode = skipGate.code
                }
                presentReminderWindow()
            case .recordMeetingSuppression:
                break
            }
        }
    }

    private func rebuildEngine(now: Date) {
        reminderEngine = ReminderEngine(
            now: now,
            settings: settings,
            meetingDetector: systemSignal.meetingDetector(now: now)
        )
        state = reminderEngine.state
    }

    private func requestNotificationPermission() {
        notificationAdapter.requestPermission { [weak self] granted in
            self?.isNotificationPermissionGranted = granted
        }
    }

    private func configureNotificationActions() {
        notificationAdapter.configureActions(
            startBreakTitle: text(.startBreakNow),
            delayTitle: text(.delayFiveMinutes),
            skipTitle: text(.skip)
        ) { [weak self] action in
            switch action {
            case .startBreak:
                self?.startBreakNow()
            case .delayFiveMinutes:
                self?.delayCurrentReminder()
            case .skip:
                self?.skipCurrentReminderFromNotification()
            }
        }
    }

    private func showNotification() {
        notificationAdapter.showNotification(
            title: text(.notificationTitle),
            body: text(.notificationBody)
        ) { [weak self] in
            self?.presentReminderWindow()
        }
    }

    private func showOnboardingIfNeeded() {
        guard !settings.hasCompletedOnboarding else { return }
        presentOnboardingWindow()
    }

    private func updateMeetingStatus(now: Date) {
        let detector = systemSignal.meetingDetector(now: now)
        if let until = systemSignal.manualMeetingUntil, until > now {
            meetingStatusText = String(format: text(.manualMeetingUntil), until.formatted(date: .omitted, time: .shortened))
        } else if detector.isMeetingActive(at: now) {
            meetingStatusText = text(.likelyMeetingActive)
        } else {
            meetingStatusText = text(.meetingModeOff)
        }
    }

    private func save() {
        guard needsSave else { return }
        do {
            try persistence.save(AppSnapshot(settings: settings, stats: stats))
            needsSave = false
        } catch {
            NSLog("EyePause failed to save snapshot: \(error.localizedDescription)")
        }
    }

    private func publishWidgetSnapshot(now: Date) {
        let nextBreakAt: Date?
        switch state {
        case .active:
            nextBreakAt = reminderEngine.nextReminderDate
        case .paused(let until):
            nextBreakAt = until
        case .due, .escalated, .forced, .exerciseRunning, .meetingSuppressed:
            nextBreakAt = nil
        }

        do {
            try widgetSnapshotStore.save(
                WidgetSnapshot(
                    nextBreakAt: nextBreakAt,
                    status: stateText,
                    updatedAt: now
                )
            )
        } catch {
            NSLog("EyePause failed to save widget snapshot: \(error.localizedDescription)")
        }
    }

    private func markDirty() {
        needsSave = true
    }

    private func markDirtyIfStatsChanged(events: [ReminderEvent], previousDay: Date) {
        if stats.today.day != previousDay || events.contains(.recordMeetingSuppression) {
            markDirty()
        }
    }

    func text(_ key: AppString) -> String {
        AppStrings.text(key, language: settings.language)
    }

    func exerciseSteps(for exercise: Exercise) -> String {
        switch exercise {
        case .distantLook:
            return text(.distantLookSteps)
        case .nearFarFocus:
            return text(.nearFarFocusSteps)
        case .closeEyes:
            return text(.closeEyesSteps)
        }
    }

    private func durationText(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(ceil(interval / 60)))
        return settings.language.minutesText(minutes)
    }

    private func presentReminderWindow() {
        windowCoordinator.presentReminderWindow(model: self, isForcedPresentation: isForcedPresentation)
    }

    private func presentSettingsWindow() {
        windowCoordinator.presentSettingsWindow(model: self)
    }

    private func presentOnboardingWindow() {
        windowCoordinator.presentOnboardingWindow(model: self)
    }

    private func dismissReminderWindow() {
        windowCoordinator.dismissReminderWindow()
    }

    private func dismissOnboardingWindow() {
        windowCoordinator.dismissOnboardingWindow()
    }
}
