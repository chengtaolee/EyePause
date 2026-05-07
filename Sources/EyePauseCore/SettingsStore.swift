import Foundation

public enum ReminderInterval: Int, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case twentyMinutes = 20
    case twentyFiveMinutes = 25
    case thirtyMinutes = 30
    case fortyFiveMinutes = 45

    public var id: Int { rawValue }
    public var seconds: TimeInterval { TimeInterval(rawValue * 60) }
    public var title: String { "\(rawValue) min" }

    public func title(language: AppLanguage) -> String {
        language.minutesText(rawValue)
    }
}

public enum AppLanguage: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case english
    case traditionalChinese
    case simplifiedChinese
    case japanese
    case korean

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english:
            return "English"
        case .traditionalChinese:
            return "繁體中文"
        case .simplifiedChinese:
            return "简体中文"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        }
    }

    public func minutesText(_ minutes: Int) -> String {
        switch self {
        case .english:
            return "\(minutes) min"
        case .traditionalChinese:
            return "\(minutes)分鐘"
        case .simplifiedChinese:
            return "\(minutes)分钟"
        case .japanese:
            return "\(minutes)分"
        case .korean:
            return "\(minutes)분"
        }
    }
}

public enum ExerciseDuration: Int, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case twentySeconds = 20
    case thirtySeconds = 30
    case fortyFiveSeconds = 45
    case sixtySeconds = 60

    public var id: Int { rawValue }

    public func title(language: AppLanguage) -> String {
        switch language {
        case .english:
            return "\(rawValue) sec"
        case .traditionalChinese, .simplifiedChinese, .japanese:
            return "\(rawValue)秒"
        case .korean:
            return "\(rawValue)초"
        }
    }
}

public enum LongBreakDuration: Int, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case twoMinutes = 2
    case threeMinutes = 3
    case fiveMinutes = 5

    public var id: Int { rawValue }
    public var seconds: Int { rawValue * 60 }

    public func title(language: AppLanguage) -> String {
        language.minutesText(rawValue)
    }
}

public enum BreakWindowPresentationMode: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case centeredWindow
    case fullScreen

    public var id: String { rawValue }

    public func title(language: AppLanguage) -> String {
        switch self {
        case .centeredWindow:
            switch language {
            case .english:
                return "Centered window"
            case .traditionalChinese:
                return "置中視窗"
            case .simplifiedChinese:
                return "居中窗口"
            case .japanese:
                return "中央ウィンドウ"
            case .korean:
                return "가운데 창"
            }
        case .fullScreen:
            switch language {
            case .english:
                return "Full screen"
            case .traditionalChinese:
                return "滿版全螢幕"
            case .simplifiedChinese:
                return "全屏满版"
            case .japanese:
                return "全画面"
            case .korean:
                return "전체 화면"
            }
        }
    }
}

public enum KeyboardShortcutModifier: String, Codable, Equatable, CaseIterable, Sendable {
    case control
    case option
    case shift
    case command
}

public struct KeyboardShortcutSetting: Codable, Equatable, Sendable {
    public var key: String
    public var modifiers: [KeyboardShortcutModifier]

    public init(key: String = "", modifiers: [KeyboardShortcutModifier] = []) {
        self.key = key
        self.modifiers = Self.normalized(modifiers)
    }

    public var isConfigured: Bool {
        !key.isEmpty && !modifiers.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case key
        case modifiers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        if let modifiers = try? container.decode([KeyboardShortcutModifier].self, forKey: .modifiers) {
            self.modifiers = Self.normalized(modifiers)
        } else {
            let legacyFlags = try container.decode(Int.self, forKey: .modifiers)
            self.modifiers = Self.modifiers(fromLegacyFlags: legacyFlags)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(modifiers, forKey: .modifiers)
    }

    private static func normalized(_ modifiers: [KeyboardShortcutModifier]) -> [KeyboardShortcutModifier] {
        KeyboardShortcutModifier.allCases.filter { modifiers.contains($0) }
    }

    private static func modifiers(fromLegacyFlags flags: Int) -> [KeyboardShortcutModifier] {
        var modifiers: [KeyboardShortcutModifier] = []
        if flags & (1 << 18) != 0 { modifiers.append(.control) }
        if flags & (1 << 19) != 0 { modifiers.append(.option) }
        if flags & (1 << 17) != 0 { modifiers.append(.shift) }
        if flags & (1 << 20) != 0 { modifiers.append(.command) }
        return modifiers
    }
}

public struct SettingsStore: Codable, Equatable, Sendable {
    public var interval: ReminderInterval
    public var isForcedModeEnabled: Bool
    public var launchAtLoginEnabled: Bool
    public var language: AppLanguage
    public var exerciseDuration: ExerciseDuration
    public var longBreakDuration: LongBreakDuration
    public var breakWindowPresentationMode: BreakWindowPresentationMode
    public var startBreakShortcut: KeyboardShortcutSetting
    public var hasCompletedOnboarding: Bool

    private enum CodingKeys: String, CodingKey {
        case interval
        case isForcedModeEnabled
        case launchAtLoginEnabled
        case language
        case exerciseDuration
        case longBreakDuration
        case breakWindowPresentationMode
        case startBreakShortcut
        case hasCompletedOnboarding
    }

    public init(
        interval: ReminderInterval = .twentyFiveMinutes,
        isForcedModeEnabled: Bool = false,
        launchAtLoginEnabled: Bool = false,
        language: AppLanguage = .english,
        exerciseDuration: ExerciseDuration = .thirtySeconds,
        longBreakDuration: LongBreakDuration = .threeMinutes,
        breakWindowPresentationMode: BreakWindowPresentationMode = .centeredWindow,
        startBreakShortcut: KeyboardShortcutSetting = KeyboardShortcutSetting(),
        hasCompletedOnboarding: Bool = false
    ) {
        self.interval = interval
        self.isForcedModeEnabled = isForcedModeEnabled
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.language = language
        self.exerciseDuration = exerciseDuration
        self.longBreakDuration = longBreakDuration
        self.breakWindowPresentationMode = breakWindowPresentationMode
        self.startBreakShortcut = startBreakShortcut
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.interval = try container.decode(ReminderInterval.self, forKey: .interval)
        self.isForcedModeEnabled = try container.decode(Bool.self, forKey: .isForcedModeEnabled)
        self.launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled) ?? false
        self.language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .english
        self.exerciseDuration = try container.decodeIfPresent(ExerciseDuration.self, forKey: .exerciseDuration) ?? .thirtySeconds
        self.longBreakDuration = try container.decodeIfPresent(LongBreakDuration.self, forKey: .longBreakDuration) ?? .threeMinutes
        self.breakWindowPresentationMode = try container.decodeIfPresent(BreakWindowPresentationMode.self, forKey: .breakWindowPresentationMode) ?? .centeredWindow
        self.startBreakShortcut = try container.decodeIfPresent(KeyboardShortcutSetting.self, forKey: .startBreakShortcut) ?? KeyboardShortcutSetting()
        self.hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(interval, forKey: .interval)
        try container.encode(isForcedModeEnabled, forKey: .isForcedModeEnabled)
        try container.encode(launchAtLoginEnabled, forKey: .launchAtLoginEnabled)
        try container.encode(language, forKey: .language)
        try container.encode(exerciseDuration, forKey: .exerciseDuration)
        try container.encode(longBreakDuration, forKey: .longBreakDuration)
        try container.encode(breakWindowPresentationMode, forKey: .breakWindowPresentationMode)
        try container.encode(startBreakShortcut, forKey: .startBreakShortcut)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
    }

    public func breakDurationSeconds(isLongBreak: Bool) -> Int {
        isLongBreak ? longBreakDuration.seconds : exerciseDuration.rawValue
    }
}
