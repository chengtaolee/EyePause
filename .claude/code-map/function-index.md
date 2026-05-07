# Function-Level Index

這份索引聚焦「使用者行為 -> 呼叫方法 -> 影響狀態/副作用」，優先覆蓋 `AppModel`。

## AppModel：使用者行為對照

### 提醒與休息操作

- 使用者行為：點「立即開始休息」
  - 方法：`startBreakNow()`
  - 內部：呼叫 `exerciseEngine.nextExercise()` 後進入 `beginExercise(_:)`
- 使用者行為：在提醒視窗選擇某個練習
  - 方法：`beginExercise(_ exercise: Exercise)`
  - 影響：設定 `currentExercise`、倒數秒數、呼叫 `reminderEngine.beginExercise`、顯示提醒視窗
- 使用者行為：練習完成（按鈕或倒數歸零）
  - 方法：`completeExercise()`
  - 影響：回到 `active`、更新統計、更新長休息進度、關閉提醒視窗、保存
- 使用者行為：延後 5 分鐘
  - 方法：`delayCurrentReminder()`
  - 影響：`reminderEngine.delay(minutes: 5)`、關閉提醒視窗、保存
- 使用者行為：略過休息（非強制）
  - 方法：`skipForcedBreak()`（在非強制狀態分支）
  - 影響：`reminderEngine.skip`、關閉提醒視窗、保存
- 使用者行為：略過強制休息（輸入 4 碼）
  - 方法：`skipForcedBreak()`（在強制狀態分支）
  - 影響：驗證 `skipGate.canSkip(with:)`，成功才 `skip`；失敗時設定 `skipError`

### 暫停與會議模式

- 使用者行為：暫停 N 分鐘
  - 方法：`pause(minutes:)`
  - 影響：`reminderEngine.pause`、更新 state、保存
- 使用者行為：專注 1 小時
  - 方法：`focusOneHour()`
  - 內部：等同 `pause(minutes: 60)`
- 使用者行為：今天暫停
  - 方法：`pauseToday()`
  - 內部：計算到明天 00:00 的分鐘數後呼叫 `pause(minutes:)`
- 使用者行為：設定手動會議 30/60/90 分鐘，或關閉
  - 方法：`setManualMeeting(minutes:)`
  - 影響：更新 `systemSignal.manualMeetingUntil`、重算 meeting status、推進引擎、必要時關閉提醒視窗、保存

### 設定與偏好

- 使用者行為：切換提醒間隔
  - 方法：`setInterval(_:)`
  - 影響：更新 `settings.interval`、`rebuildEngine`、保存
- 使用者行為：切換語言
  - 方法：`setLanguage(_:)`
  - 影響：更新語言、保存、刷新會議狀態文案
- 使用者行為：切換短練習時長
  - 方法：`setExerciseDuration(_:)`
  - 影響：更新設定並保存
- 使用者行為：切換長休息時長
  - 方法：`setLongBreakDuration(_:)`
  - 影響：更新設定並保存
- 使用者行為：切換強制模式
  - 方法：`toggleForcedMode()`
  - 影響：更新設定、同步 `reminderEngine.settings`、保存
- 使用者行為：切換登入時啟動
  - 方法：`setLaunchAtLogin(_:)`
  - 影響：呼叫 `SMAppService.mainApp.register/unregister`，成功才保存

### 快捷鍵

- 使用者行為：開始錄製快捷鍵
  - 方法：`startRecordingShortcut()`
  - 影響：`isRecordingShortcut = true`
- 使用者行為：清除快捷鍵
  - 方法：`clearStartBreakShortcut()`
  - 影響：重設 `startBreakShortcut`、關閉錄製、保存
- 使用者行為：按下鍵盤（錄製模式）
  - 方法：`captureShortcut(from:)`
  - 影響：若 key+modifier 合法，寫入 `settings.startBreakShortcut` 並保存
- 使用者行為：按下已設定快捷鍵（一般/全域）
  - 方法：`installShortcutMonitors()` 內事件處理
  - 影響：符合條件時呼叫 `startBreakNow()`

### 視窗與畫面

- 使用者行為：點「設定」
  - 方法：`showSettings()`
  - 內部：`presentSettingsWindow()`
- 系統/引擎觸發：需要顯示提醒
  - 方法：`presentReminderWindow()`
  - 影響：依強制模式決定 window level 與 frame
- 系統/流程觸發：提醒結束或被延後/略過
  - 方法：`dismissReminderWindow()`

### 內部週期（非直接 UI 點擊，但最重要）

- 每秒驅動主循環
  - 方法：`tick(now:)`
  - 角色：同步 meeting detector、推進 `ReminderEngine`、處理事件、保存
- 事件分派
  - 方法：`handle(_ events:)`
  - 角色：`showNotification`、`showProminentReminder`、強制碼生成
- 快照保存
  - 方法：`save()`
  - 角色：避免重複寫入，僅在快照變更時持久化

## ReminderEngine：狀態機關鍵函式

- `advance(to:stats:)`：推進狀態機與輸出事件（最核心）
- `beginExercise(_:)`：進入 `exerciseRunning`
- `delay(minutes:now:)`：回 `active` 並重設提醒點
- `pause(minutes:now:)`：進入 `paused(until:)`
- `completeExercise(_:now:stats:)`：完成休息、記錄 completed
- `skip(now:stats:)`：略過休息、記錄 skipped

## StatsStore：統計更新函式

- `recordCompletedBreak(now:)`
- `recordSkippedBreak(now:)`
- `recordMeetingSuppression(now:)`
- `rolloverIfNeeded(now:)`（跨日切換）
- `continuousWorkDuration(now:)`
- `resetActiveWorkIfStale(now:threshold:)`

## PersistenceStore：資料存取邊界

- `load()`：讀取版本化快照，舊格式 fallback
- `save(_:)`：儲存版本化快照（`schemaVersion + snapshot`）

## 快速定位建議（除錯順序）

1. 行為有觸發但畫面不對：先看 `AppModel.handle(_:)`、`presentReminderWindow()`
2. 行為完全沒觸發：先看 `tick(now:)` -> `ReminderEngine.advance`
3. 數據不對：看 `StatsStore.record*` 與 `AppModel.completeExercise/skipForcedBreak`
4. 重開後遺失：看 `AppModel.save()`、`PersistenceStore.load/save`
