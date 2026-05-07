# Maintenance Playbook

## 常見需求 -> 修改入口

- 調整提醒規則（例如逾時秒數、狀態轉移）
  - 先改 `Sources/EyePauseCore/ReminderEngine.swift`
  - 再補 `Tests/EyePauseCoreTests/ReminderEngineTests.swift`
- 新增/調整會議偵測來源
  - 核心模型：`Sources/EyePauseCore/MeetingDetector.swift`
  - 系統整合：`Sources/EyePauseApp/SystemMeetingSignal.swift`
  - 補測試：`Tests/EyePauseCoreTests/MeetingDetectorTests.swift`
- 調整練習與長休息策略
  - 練習輪播：`Sources/EyePauseCore/ExerciseEngine.swift`
  - 長休息觸發與倒數：`Sources/EyePauseApp/AppModel.swift`
- 新增設定項目
  - model：`Sources/EyePauseCore/SettingsStore.swift`
  - UI：`Sources/EyePauseApp/SettingsView.swift`
  - 保存：`Sources/EyePauseCore/Persistence.swift`（必要時提升 schema）
- 新增語系文案
  - `Sources/EyePauseApp/AppStrings.swift`

## 先看哪裡最快定位問題

- 提醒沒有跳出：
  - `AppModel.tick` -> `ReminderEngine.advance` -> `handle(events)`
- 強制略過碼異常：
  - `ForcedSkipGate`、`AppModel.skipForcedBreak`、`ReminderWindowView.forcedSkipView`
- 統計數字不對：
  - `StatsStore.record*` 與 `rolloverIfNeeded`
- 重新開啟 App 後設定遺失：
  - `PersistenceStore.load/save` 與 `AppModel.save`

## 修改時的安全邊界

- 建議優先維持邊界：View -> `AppModel` -> Core
- 避免在 View 直接操作 `ReminderEngine` 或 `StatsStore`
- Core 盡量不引入 UI 依賴，確保測試仍可快速執行

## 最小驗證清單

1. `swift test`
2. `swift run EyePause` 手動驗證：
   - 立即休息
   - 延後 5 分鐘
   - 暫停（10 分鐘或 1 小時）
   - 手動會議模式開關
   - 強制模式略過碼輸入
3. 關閉後重開，確認設定與統計可載入

## 未來擴充建議（維護角度）

- 若 UI 行為持續增加，可把 `AppModel` 依責任拆分：
  - Reminder orchestration
  - Window presentation
  - Keyboard shortcut handling
  - Notification handling
- 若要支援瀏覽器會議偵測，可新增 detector adapter，不直接汙染 `ReminderEngine`
