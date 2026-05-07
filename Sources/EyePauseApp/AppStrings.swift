import EyePauseCore
import Foundation

enum AppString: String, Sendable {
    case appName
    case active
    case breakDue
    case breakOverdue
    case exerciseRunning
    case meetingSuppression
    case forcedBreak
    case meetingModeOff
    case likelyMeetingActive
    case startBreakNow
    case reminderInterval
    case delayFiveMinutes
    case pause
    case meetingMode
    case off
    case forcedMode
    case today
    case completedSkipped
    case meetingSuppressed
    case continuousWork
    case settings
    case quit
    case timeToRest
    case chooseExercise
    case skip
    case complete
    case enterCode
    case skipForcedBreak
    case codeMismatch
    case launchAtLogin
    case launchAtLoginFailed
    case statistics
    case completedToday
    case skippedToday
    case meetingSuppressedToday
    case privacy
    case privacyBody
    case language
    case manualMeetingUntil
    case distantLookTitle
    case nearFarFocusTitle
    case closeEyesTitle
    case distantLookSubtitle
    case nearFarFocusSubtitle
    case closeEyesSubtitle
    case exerciseDuration
    case longBreakDuration
    case breakWindowPresentation
    case startBreakShortcut
    case recordShortcut
    case clearShortcut
    case recordingShortcutPrompt
    case noShortcut
    case longBreakTitle
    case longBreakSubtitle
    case dashboard
    case now
    case nextBreak
    case nextBreakIn
    case nextBreakDue
    case focusOneHour
    case pauseTenMinutes
    case pauseToday
    case quickActions
    case completionRate
    case sevenDayCompleted
    case sevenDayAttempted
    case breakPlan
    case longBreakProgress
    case longBreakReady
    case systemNotes
    case notifications
    case onboardingTitle
    case onboardingEnableNotifications
    case onboardingComplete
    case notificationGranted
    case notificationDenied
    case notificationDevelopmentFallback
    case notificationTitle
    case notificationBody
    case meetingModeExplanation
    case exerciseGuidance
    case distantLookSteps
    case nearFarFocusSteps
    case closeEyesSteps
}

struct AppStrings {
    static func text(_ key: AppString, language: AppLanguage) -> String {
        table[language]?[key] ?? table[.english]?[key] ?? key.rawValue
    }

    private static let table: [AppLanguage: [AppString: String]] = [
        .english: [
            .appName: "EyePause",
            .active: "Active",
            .breakDue: "Break due",
            .breakOverdue: "Break overdue",
            .exerciseRunning: "Exercise running",
            .meetingSuppression: "Meeting suppression",
            .forcedBreak: "Forced break",
            .meetingModeOff: "Meeting mode off",
            .likelyMeetingActive: "Likely meeting active",
            .startBreakNow: "Start Break Now",
            .reminderInterval: "Reminder Interval",
            .delayFiveMinutes: "Delay 5 min",
            .pause: "Pause",
            .meetingMode: "Meeting Mode",
            .off: "Off",
            .forcedMode: "Forced Mode",
            .today: "Today",
            .completedSkipped: "Completed %d  Skipped %d",
            .meetingSuppressed: "Meeting-suppressed %d",
            .continuousWork: "Continuous work %@",
            .settings: "Settings",
            .quit: "Quit EyePause",
            .timeToRest: "Time to Rest Your Eyes",
            .chooseExercise: "Choose a short exercise.",
            .skip: "Skip",
            .complete: "Complete",
            .enterCode: "This skip code is a friction barrier for forced breaks.",
            .skipForcedBreak: "Skip Forced Break",
            .codeMismatch: "Code does not match.",
            .launchAtLogin: "Launch at login",
            .launchAtLoginFailed: "Could not update launch at login: %@",
            .statistics: "Statistics",
            .completedToday: "Completed today",
            .skippedToday: "Skipped today",
            .meetingSuppressedToday: "Meeting-suppressed today",
            .privacy: "Privacy",
            .privacyBody: "EyePause stores settings and simple break counts locally. It does not record websites, meeting content, audio, camera images, or keyboard input.",
            .language: "Language",
            .manualMeetingUntil: "Manual meeting until %@",
            .distantLookTitle: "20-20-20",
            .nearFarFocusTitle: "Near/Far Focus",
            .closeEyesTitle: "Close Eyes",
            .distantLookSubtitle: "Look beyond the screen and let the horizon breathe.",
            .nearFarFocusSubtitle: "Follow the target as it shifts between near and far.",
            .closeEyesSubtitle: "Let the screen fade while the breathing ring slows down."
            ,
            .exerciseDuration: "Exercise duration",
            .longBreakDuration: "Long break duration",
            .breakWindowPresentation: "Break screen",
            .startBreakShortcut: "Start break shortcut",
            .recordShortcut: "Record shortcut",
            .clearShortcut: "Clear shortcut",
            .recordingShortcutPrompt: "Press the new shortcut.",
            .noShortcut: "Not set",
            .longBreakTitle: "Long Rest",
            .longBreakSubtitle: "A longer pause is due. Let your eyes fully reset.",
            .dashboard: "Dashboard",
            .now: "Now",
            .nextBreak: "Next break",
            .nextBreakIn: "Next break in %@",
            .nextBreakDue: "Due now",
            .focusOneHour: "Focus 1 hour",
            .pauseTenMinutes: "Pause 10 min",
            .pauseToday: "Pause Today",
            .quickActions: "Quick Actions",
            .completionRate: "Completion rate",
            .sevenDayCompleted: "7-day completed",
            .sevenDayAttempted: "7-day attempts",
            .breakPlan: "Break Plan",
            .longBreakProgress: "Long break in %d short breaks",
            .longBreakReady: "Long break ready",
            .systemNotes: "System Notes",
            .notifications: "Notifications",
            .onboardingTitle: "Set up EyePause",
            .onboardingEnableNotifications: "Enable Notifications",
            .onboardingComplete: "Start Using EyePause",
            .notificationGranted: "System notifications are enabled.",
            .notificationDenied: "System notifications are not enabled yet.",
            .notificationDevelopmentFallback: "SwiftPM development runs use the prominent reminder window fallback.",
            .notificationTitle: "EyePause",
            .notificationBody: "Time to rest your eyes.",
            .meetingModeExplanation: "Meeting detection is best effort from foreground apps. Manual meeting mode is the reliable control.",
            .exerciseGuidance: "Exercises show step-by-step guidance during the reminder window.",
            .distantLookSteps: "Look at something at least 20 feet away. Relax your focus and keep your shoulders down.",
            .nearFarFocusSteps: "Alternate between a near point and a far point every few seconds.",
            .closeEyesSteps: "Close your eyes or blink slowly. Keep breathing steady until the timer ends."
        ],
        .traditionalChinese: [
            .appName: "EyePause",
            .active: "運作中",
            .breakDue: "該休息了",
            .breakOverdue: "休息提醒逾時",
            .exerciseRunning: "練習進行中",
            .meetingSuppression: "會議中靜默",
            .forcedBreak: "強制休息",
            .meetingModeOff: "會議模式關閉",
            .likelyMeetingActive: "可能正在會議中",
            .startBreakNow: "立即開始休息",
            .reminderInterval: "提醒間隔",
            .delayFiveMinutes: "延後 5 分鐘",
            .pause: "暫停",
            .meetingMode: "會議模式",
            .off: "關閉",
            .forcedMode: "強制模式",
            .today: "今日",
            .completedSkipped: "完成 %d  略過 %d",
            .meetingSuppressed: "會議靜默 %d",
            .continuousWork: "連續工作 %@",
            .settings: "設定",
            .quit: "結束 EyePause",
            .timeToRest: "該讓眼睛休息了",
            .chooseExercise: "選擇一個短練習。",
            .skip: "略過",
            .complete: "完成",
            .enterCode: "這個略過代碼是強制休息的阻力門檻。",
            .skipForcedBreak: "略過強制休息",
            .codeMismatch: "代碼不符合。",
            .launchAtLogin: "登入時啟動",
            .launchAtLoginFailed: "無法更新登入時啟動：%@",
            .statistics: "統計",
            .completedToday: "今日完成",
            .skippedToday: "今日略過",
            .meetingSuppressedToday: "今日會議靜默",
            .privacy: "隱私",
            .privacyBody: "EyePause 只會在本機儲存設定與簡單休息次數，不記錄網站、會議內容、音訊、攝影機影像或鍵盤輸入。",
            .language: "語言",
            .manualMeetingUntil: "手動會議到 %@",
            .distantLookTitle: "20-20-20 遠方休息",
            .nearFarFocusTitle: "遠近對焦",
            .closeEyesTitle: "閉眼／眨眼節奏",
            .distantLookSubtitle: "把視線移到螢幕外，讓眼睛看向更遠的地方。",
            .nearFarFocusSubtitle: "跟著焦點目標在近與遠之間切換。",
            .closeEyesSubtitle: "讓畫面退到背景，跟著呼吸環放慢節奏。"
            ,
            .exerciseDuration: "練習時間",
            .longBreakDuration: "長休息時間",
            .breakWindowPresentation: "休息畫面",
            .startBreakShortcut: "立即休息快捷鍵",
            .recordShortcut: "錄製快捷鍵",
            .clearShortcut: "清除快捷鍵",
            .recordingShortcutPrompt: "請按下新的快捷鍵。",
            .noShortcut: "未設定",
            .longBreakTitle: "長休息",
            .longBreakSubtitle: "該做一次較長的休息了，讓眼睛完整放鬆。",
            .dashboard: "Dashboard",
            .now: "目前狀態",
            .nextBreak: "下次休息",
            .nextBreakIn: "%@ 後休息",
            .nextBreakDue: "現在該休息",
            .focusOneHour: "專注 1 小時",
            .pauseTenMinutes: "暫停 10 分鐘",
            .pauseToday: "今天暫停",
            .quickActions: "快速操作",
            .completionRate: "完成率",
            .sevenDayCompleted: "7 天完成",
            .sevenDayAttempted: "7 天嘗試",
            .breakPlan: "休息計畫",
            .longBreakProgress: "再 %d 次短休息進入長休息",
            .longBreakReady: "可以進行長休息",
            .systemNotes: "系統說明",
            .notifications: "通知",
            .onboardingTitle: "設定 EyePause",
            .onboardingEnableNotifications: "啟用通知",
            .onboardingComplete: "開始使用 EyePause",
            .notificationGranted: "系統通知已啟用。",
            .notificationDenied: "尚未啟用系統通知。",
            .notificationDevelopmentFallback: "SwiftPM 開發執行會改用醒目的提醒視窗。",
            .notificationTitle: "EyePause",
            .notificationBody: "該讓眼睛休息了。",
            .meetingModeExplanation: "會議偵測是依前景 App 推測；手動會議模式才是可靠控制。",
            .exerciseGuidance: "提醒視窗會顯示逐步練習指引。",
            .distantLookSteps: "看向至少 20 英尺外的物體，放鬆對焦並放下肩膀。",
            .nearFarFocusSteps: "每隔幾秒在近處與遠處焦點之間切換。",
            .closeEyesSteps: "閉眼或慢慢眨眼，穩定呼吸直到倒數結束。"
        ],
        .simplifiedChinese: [
            .appName: "EyePause",
            .active: "运行中",
            .breakDue: "该休息了",
            .breakOverdue: "休息提醒逾时",
            .exerciseRunning: "练习进行中",
            .meetingSuppression: "会议中静默",
            .forcedBreak: "强制休息",
            .meetingModeOff: "会议模式关闭",
            .likelyMeetingActive: "可能正在会议中",
            .startBreakNow: "立即开始休息",
            .reminderInterval: "提醒间隔",
            .delayFiveMinutes: "延后 5 分钟",
            .pause: "暂停",
            .meetingMode: "会议模式",
            .off: "关闭",
            .forcedMode: "强制模式",
            .today: "今日",
            .completedSkipped: "完成 %d  跳过 %d",
            .meetingSuppressed: "会议静默 %d",
            .continuousWork: "连续工作 %@",
            .settings: "设置",
            .quit: "退出 EyePause",
            .timeToRest: "该让眼睛休息了",
            .chooseExercise: "选择一个短练习。",
            .skip: "跳过",
            .complete: "完成",
            .enterCode: "这个跳过代码是强制休息的阻力门槛。",
            .skipForcedBreak: "跳过强制休息",
            .codeMismatch: "代码不匹配。",
            .launchAtLogin: "登录时启动",
            .launchAtLoginFailed: "无法更新登录时启动：%@",
            .statistics: "统计",
            .completedToday: "今日完成",
            .skippedToday: "今日跳过",
            .meetingSuppressedToday: "今日会议静默",
            .privacy: "隐私",
            .privacyBody: "EyePause 只会在本机存储设置和简单休息次数，不记录网站、会议内容、音频、摄像头图像或键盘输入。",
            .language: "语言",
            .manualMeetingUntil: "手动会议到 %@",
            .distantLookTitle: "20-20-20 远方休息",
            .nearFarFocusTitle: "远近对焦",
            .closeEyesTitle: "闭眼／眨眼节奏",
            .distantLookSubtitle: "把视线移到屏幕外，让眼睛看向更远的地方。",
            .nearFarFocusSubtitle: "跟着焦点目标在近与远之间切换。",
            .closeEyesSubtitle: "让画面退到背景，跟着呼吸环放慢节奏。"
            ,
            .exerciseDuration: "练习时间",
            .longBreakDuration: "长休息时间",
            .breakWindowPresentation: "休息画面",
            .startBreakShortcut: "立即休息快捷键",
            .recordShortcut: "录制快捷键",
            .clearShortcut: "清除快捷键",
            .recordingShortcutPrompt: "请按下新的快捷键。",
            .noShortcut: "未设置",
            .longBreakTitle: "长休息",
            .longBreakSubtitle: "该做一次较长的休息了，让眼睛完整放松。",
            .dashboard: "Dashboard",
            .now: "当前状态",
            .nextBreak: "下次休息",
            .nextBreakIn: "%@ 后休息",
            .nextBreakDue: "现在该休息",
            .focusOneHour: "专注 1 小时",
            .pauseTenMinutes: "暂停 10 分钟",
            .pauseToday: "今天暂停",
            .quickActions: "快捷操作",
            .completionRate: "完成率",
            .sevenDayCompleted: "7 天完成",
            .sevenDayAttempted: "7 天尝试",
            .breakPlan: "休息计划",
            .longBreakProgress: "再 %d 次短休息进入长休息",
            .longBreakReady: "可以进行长休息",
            .systemNotes: "系统说明",
            .notifications: "通知",
            .onboardingTitle: "设置 EyePause",
            .onboardingEnableNotifications: "启用通知",
            .onboardingComplete: "开始使用 EyePause",
            .notificationGranted: "系统通知已启用。",
            .notificationDenied: "尚未启用系统通知。",
            .notificationDevelopmentFallback: "SwiftPM 开发运行会改用醒目的提醒窗口。",
            .notificationTitle: "EyePause",
            .notificationBody: "该让眼睛休息了。",
            .meetingModeExplanation: "会议检测是基于前台 App 推测；手动会议模式才是可靠控制。",
            .exerciseGuidance: "提醒窗口会显示逐步练习指引。",
            .distantLookSteps: "看向至少 20 英尺外的物体，放松对焦并放下肩膀。",
            .nearFarFocusSteps: "每隔几秒在近处与远处焦点之间切换。",
            .closeEyesSteps: "闭眼或慢慢眨眼，保持呼吸平稳直到倒数结束。"
        ],
        .japanese: [
            .appName: "EyePause",
            .active: "稼働中",
            .breakDue: "休憩の時間です",
            .breakOverdue: "休憩が遅れています",
            .exerciseRunning: "エクササイズ中",
            .meetingSuppression: "会議中は通知を抑制",
            .forcedBreak: "強制休憩",
            .meetingModeOff: "会議モードはオフ",
            .likelyMeetingActive: "会議中の可能性があります",
            .startBreakNow: "今すぐ休憩",
            .reminderInterval: "通知間隔",
            .delayFiveMinutes: "5 分延期",
            .pause: "一時停止",
            .meetingMode: "会議モード",
            .off: "オフ",
            .forcedMode: "強制モード",
            .today: "今日",
            .completedSkipped: "完了 %d  スキップ %d",
            .meetingSuppressed: "会議中抑制 %d",
            .continuousWork: "連続作業 %@",
            .settings: "設定",
            .quit: "EyePause を終了",
            .timeToRest: "目を休める時間です",
            .chooseExercise: "短いエクササイズを選択してください。",
            .skip: "スキップ",
            .complete: "完了",
            .enterCode: "このスキップコードは強制休憩のための抵抗です。",
            .skipForcedBreak: "強制休憩をスキップ",
            .codeMismatch: "コードが一致しません。",
            .launchAtLogin: "ログイン時に起動",
            .launchAtLoginFailed: "ログイン時起動を更新できませんでした: %@",
            .statistics: "統計",
            .completedToday: "今日の完了",
            .skippedToday: "今日のスキップ",
            .meetingSuppressedToday: "今日の会議中抑制",
            .privacy: "プライバシー",
            .privacyBody: "EyePause は設定と簡単な休憩回数のみをローカルに保存します。Web サイト、会議内容、音声、カメラ画像、キーボード入力は記録しません。",
            .language: "言語",
            .manualMeetingUntil: "手動会議モード %@ まで",
            .distantLookTitle: "20-20-20 遠くを見る",
            .nearFarFocusTitle: "近遠フォーカス",
            .closeEyesTitle: "目を閉じる／まばたき",
            .distantLookSubtitle: "画面の外に視線を移し、遠くを見る時間を作ります。",
            .nearFarFocusSubtitle: "近くと遠くを行き来するターゲットを追います。",
            .closeEyesSubtitle: "画面を背景に退け、呼吸リングに合わせてゆっくりします。"
            ,
            .exerciseDuration: "エクササイズ時間",
            .longBreakDuration: "長めの休憩時間",
            .breakWindowPresentation: "休憩画面",
            .startBreakShortcut: "今すぐ休憩ショートカット",
            .recordShortcut: "ショートカットを記録",
            .clearShortcut: "ショートカットを削除",
            .recordingShortcutPrompt: "新しいショートカットを押してください。",
            .noShortcut: "未設定",
            .longBreakTitle: "長めの休憩",
            .longBreakSubtitle: "長めの休憩の時間です。目をしっかり休ませましょう。",
            .dashboard: "ダッシュボード",
            .now: "現在の状態",
            .nextBreak: "次の休憩",
            .nextBreakIn: "%@ 後に休憩",
            .nextBreakDue: "今すぐ休憩",
            .focusOneHour: "1時間集中",
            .pauseTenMinutes: "10分一時停止",
            .pauseToday: "今日は休む",
            .quickActions: "クイック操作",
            .completionRate: "完了率",
            .sevenDayCompleted: "7日間の完了",
            .sevenDayAttempted: "7日間の試行",
            .breakPlan: "休憩プラン",
            .longBreakProgress: "あと %d 回の短い休憩で長めの休憩",
            .longBreakReady: "長めの休憩が可能",
            .systemNotes: "システムについて",
            .notifications: "通知",
            .onboardingTitle: "EyePause を設定",
            .onboardingEnableNotifications: "通知を有効にする",
            .onboardingComplete: "EyePause を使い始める",
            .notificationGranted: "システム通知が有効です。",
            .notificationDenied: "システム通知はまだ有効になっていません。",
            .notificationDevelopmentFallback: "SwiftPM での開発実行では目立つ通知ウィンドウを代替表示します。",
            .notificationTitle: "EyePause",
            .notificationBody: "目を休める時間です。",
            .meetingModeExplanation: "会議検出はフォアグラウンドアプリからの推定です。手動会議モードが確実な制御方法です。",
            .exerciseGuidance: "通知ウィンドウにエクササイズの手順が表示されます。",
            .distantLookSteps: "少なくとも 6m（20 フィート）以上離れたものを見てください。焦点をゆるめ、肩の力を抜きましょう。",
            .nearFarFocusSteps: "数秒ごとに近くと遠くの焦点を交互に見てください。",
            .closeEyesSteps: "目を閉じるか、ゆっくりまばたきしてください。タイマーが終わるまで呼吸を整えましょう。"
        ],
        .korean: [
            .appName: "EyePause",
            .active: "실행 중",
            .breakDue: "쉴 시간입니다",
            .breakOverdue: "휴식 알림 지연",
            .exerciseRunning: "운동 진행 중",
            .meetingSuppression: "회의 중 알림 억제",
            .forcedBreak: "강제 휴식",
            .meetingModeOff: "회의 모드 꺼짐",
            .likelyMeetingActive: "회의 중일 수 있음",
            .startBreakNow: "지금 휴식 시작",
            .reminderInterval: "알림 간격",
            .delayFiveMinutes: "5분 미루기",
            .pause: "일시 정지",
            .meetingMode: "회의 모드",
            .off: "끄기",
            .forcedMode: "강제 모드",
            .today: "오늘",
            .completedSkipped: "완료 %d  건너뜀 %d",
            .meetingSuppressed: "회의 중 억제 %d",
            .continuousWork: "연속 작업 %@",
            .settings: "설정",
            .quit: "EyePause 종료",
            .timeToRest: "눈을 쉴 시간입니다",
            .chooseExercise: "짧은 운동을 선택하세요.",
            .skip: "건너뛰기",
            .complete: "완료",
            .enterCode: "이 건너뛰기 코드는 강제 휴식을 위한 마찰 장벽입니다.",
            .skipForcedBreak: "강제 휴식 건너뛰기",
            .codeMismatch: "코드가 일치하지 않습니다.",
            .launchAtLogin: "로그인 시 실행",
            .launchAtLoginFailed: "로그인 시 실행을 업데이트할 수 없습니다: %@",
            .statistics: "통계",
            .completedToday: "오늘 완료",
            .skippedToday: "오늘 건너뜀",
            .meetingSuppressedToday: "오늘 회의 중 억제",
            .privacy: "개인정보",
            .privacyBody: "EyePause는 설정과 간단한 휴식 횟수만 로컬에 저장합니다. 웹사이트, 회의 내용, 오디오, 카메라 이미지, 키보드 입력은 기록하지 않습니다.",
            .language: "언어",
            .manualMeetingUntil: "수동 회의 모드 %@까지",
            .distantLookTitle: "20-20-20 먼 곳 보기",
            .nearFarFocusTitle: "근거리／원거리 초점",
            .closeEyesTitle: "눈 감기／깜빡임",
            .distantLookSubtitle: "시선을 화면 밖으로 옮겨 더 먼 곳을 바라보세요.",
            .nearFarFocusSubtitle: "가까움과 멀어짐을 오가는 초점 목표를 따라가세요.",
            .closeEyesSubtitle: "화면을 배경으로 두고 호흡 링에 맞춰 천천히 쉬세요."
            ,
            .exerciseDuration: "운동 시간",
            .longBreakDuration: "긴 휴식 시간",
            .breakWindowPresentation: "휴식 화면",
            .startBreakShortcut: "즉시 휴식 단축키",
            .recordShortcut: "단축키 기록",
            .clearShortcut: "단축키 지우기",
            .recordingShortcutPrompt: "새 단축키를 누르세요.",
            .noShortcut: "설정 안 됨",
            .longBreakTitle: "긴 휴식",
            .longBreakSubtitle: "긴 휴식이 필요합니다. 눈을 충분히 쉬게 하세요.",
            .dashboard: "대시보드",
            .now: "현재 상태",
            .nextBreak: "다음 휴식",
            .nextBreakIn: "%@ 후 휴식",
            .nextBreakDue: "지금 휴식하세요",
            .focusOneHour: "1시간 집중",
            .pauseTenMinutes: "10분 일시 정지",
            .pauseToday: "오늘 일시 정지",
            .quickActions: "빠른 작업",
            .completionRate: "완료율",
            .sevenDayCompleted: "7일 완료",
            .sevenDayAttempted: "7일 시도",
            .breakPlan: "휴식 계획",
            .longBreakProgress: "짧은 휴식 %d번 후 긴 휴식",
            .longBreakReady: "긴 휴식 가능",
            .systemNotes: "시스템 안내",
            .notifications: "알림",
            .onboardingTitle: "EyePause 설정",
            .onboardingEnableNotifications: "알림 켜기",
            .onboardingComplete: "EyePause 시작하기",
            .notificationGranted: "시스템 알림이 활성화되었습니다.",
            .notificationDenied: "시스템 알림이 아직 활성화되지 않았습니다.",
            .notificationDevelopmentFallback: "SwiftPM 개발 실행에서는 눈에 띄는 알림 창으로 대체합니다.",
            .notificationTitle: "EyePause",
            .notificationBody: "눈을 쉴 시간입니다.",
            .meetingModeExplanation: "회의 감지는 포그라운드 앱 기반 추정입니다. 수동 회의 모드가 확실한 제어 방법입니다.",
            .exerciseGuidance: "알림 창에 운동 단계별 안내가 표시됩니다.",
            .distantLookSteps: "최소 6m(20피트) 이상 떨어진 것을 바라보세요. 초점을 풀고 어깨에 힘을 빼세요.",
            .nearFarFocusSteps: "몇 초마다 가까운 곳과 먼 곳의 초점을 번갈아 바라보세요.",
            .closeEyesSteps: "눈을 감거나 천천히 깜빡이세요. 타이머가 끝날 때까지 호흡을 안정적으로 유지하세요."
        ]
    ]
}
