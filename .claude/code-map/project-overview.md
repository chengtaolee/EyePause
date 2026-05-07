# Project Overview

## Package 與 Target 關係

- `EyePauseCore`（library）
  - 純邏輯層，包含提醒狀態機、統計、設定、持久化、會議判斷
- `EyePauseApp`（executable）
  - SwiftUI + AppKit 應用層，依賴 `EyePauseCore`
- `EyePauseCoreTests`（test target）
  - 驗證核心邏輯，不直接測 UI

## 應用層（Sources/EyePauseApp）

- `EyePauseApp.swift`
  - App 入口，建立 `AppModel`，掛上 menu bar 視窗
- `AppModel.swift`
  - 應用協調核心（state owner）
  - 將 `ReminderEngine` 事件轉成 UI 行為（通知、提醒視窗、設定窗）
  - 管理計時器、快捷鍵、會議模式、持久化
- `MenuBarView.swift`
  - MenuBar 主操作入口（立即休息、暫停、會議模式、設定）
- `SettingsView.swift`
  - 設定頁容器，含 dashboard、語言/間隔/時長、快捷鍵、隱私資訊
- `DashboardView.swift`
  - 統計與狀態儀表板視圖（現在狀態、快速操作、七日統計）
- `ReminderWindowView.swift`
  - 休息提醒與練習畫面（一般與強制模式）
- `SystemMeetingSignal.swift`
  - 封裝前景 App 判斷，輸出 `MeetingDetector`
- `AppStrings.swift`
  - 多語文案表（英/繁中/簡中/日/韓）

## 核心層（Sources/EyePauseCore）

- `ReminderEngine.swift`
  - 核心提醒狀態機
  - 狀態：`active`、`due`、`escalated`、`forced`、`exerciseRunning`、`paused`、`meetingSuppressed`
  - 事件：`showNotification`、`showProminentReminder`、`recordMeetingSuppression`
- `MeetingDetector.swift`
  - 會議判斷模型（手動會議、前景 App、麥克風/相機訊號）
- `ExerciseEngine.swift`
  - 練習輪播與強制略過碼（`ForcedSkipGate`）
- `SettingsStore.swift`
  - 使用者設定模型與 enum（提醒間隔、語言、練習時長、長休息時長、快捷鍵）
- `StatsStore.swift`
  - 今日統計、七日趨勢、連續工作時間
- `Persistence.swift`
  - 快照結構 `AppSnapshot` 與 `UserDefaults` 持久化（含 schemaVersion）

## 主要資料模型

- `SettingsStore`
  - 儲存使用者偏好，並作為 `ReminderEngine.settings`
- `StatsStore`
  - 儲存行為結果（完成/略過/會議抑制）與趨勢
- `ReminderState`
  - 提醒狀態機唯一狀態來源
- `AppSnapshot`
  - `settings + stats` 的存取邊界

## 關鍵依賴方向

- View -> `AppModel` -> `EyePauseCore`（單向）
- `AppModel` 是唯一協調層，View 不直接操作 `ReminderEngine`
- Core 不依賴 AppKit/SwiftUI，維持可測試性
