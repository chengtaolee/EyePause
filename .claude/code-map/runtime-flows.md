# Runtime Flows

## 1) 啟動流程

1. `EyePauseApp` 建立 `AppModel`
2. `AppModel.init`：
   - `PersistenceStore.load()` 讀取快照
   - 初始化 `ReminderEngine(settings, meetingDetector)`
   - 安裝通知授權、快捷鍵監聽、喚醒監聽
   - 啟動每秒 `tick`
3. MenuBar UI 綁定 `AppModel` published state

## 2) 每秒 Tick 主流程（`AppModel.tick`）

1. 若 `currentExercise != nil`：
   - 倒數 `remainingExerciseSeconds`
   - 到 0 時 `completeExercise()`
2. 否則：
   - 更新會議狀態文案
   - 同步 `reminderEngine.settings`
   - 同步 `reminderEngine.meetingDetector`
   - 呼叫 `reminderEngine.advance(to:stats:)`
   - 處理事件 `handle(events)`
   - `save()` 快照

## 3) 提醒狀態機（`ReminderEngine`）

- `active` ->（到點）`due` + `.showNotification`
- `due` ->（2 分鐘未處理）`escalated` 或 `forced` + `.showProminentReminder`
- `due/escalated/forced` +（會議偵測）`meetingSuppressed` + `.recordMeetingSuppression`（每次提醒最多一次）
- `meetingSuppressed` +（會議結束後 2 分鐘）`escalated` + `.showProminentReminder`
- `exerciseRunning`：`advance` 不再發提醒事件
- `completeExercise` / `skip` / `delay`：都會回到 `active` 並重設下一次提醒時間

## 4) 提醒視窗與強制模式

- 事件 `.showProminentReminder(forced: Bool)` 由 `AppModel.handle` 處理
- 強制模式時：
  - 建立 `ForcedSkipGate` 4 位數碼
  - `ReminderWindowView` 顯示碼與輸入欄
  - 僅在 `skipInput == code` 時可略過

## 5) 會議抑制來源

- 手動會議：`setManualMeeting(minutes:)` 寫入 `manualMeetingUntil`
- 系統訊號：`SystemMeetingSignal` 依前景 App bundle id 判斷（Zoom/Teams/FaceTime）
- 合成為 `MeetingDetector` 給 `ReminderEngine`

## 6) 資料保存流程

- `AppModel.save()` 將 `SettingsStore + StatsStore` 包為 `AppSnapshot`
- 與 `lastSavedSnapshot` 相同則不寫入
- `PersistenceStore.save()` 以 versioned envelope 存到 `UserDefaults`

## 7) 測試對應（核心）

- `ReminderEngineTests`：狀態機轉移、會議抑制、catch-up、delay/complete
- `MeetingDetectorTests`：會議判斷與結束時間邏輯
- `ExerciseEngineTests`：練習輪播與 skip gate 驗證
- `StoreTests`：設定/統計模型與彙總邏輯
- `PersistenceTests`：快照讀寫與版本封裝
