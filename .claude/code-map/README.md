# EyePause Code Map

本目錄提供可維護導向的程式碼地圖，方便快速理解專案結構與修改入口。

## 文件索引

- `project-overview.md`：專案分層、檔案責任與核心資料模型
- `runtime-flows.md`：從啟動到提醒、會議抑制、休息完成的執行流程
- `maintenance-playbook.md`：常見維護任務對應檔案與測試清單
- `function-index.md`：函式級別索引（使用者行為對應 `AppModel`/Core 方法）

## 目錄快照

- `Sources/EyePauseApp/`
  - macOS UI 與 App 協調層（`AppModel` 為核心）
- `Sources/EyePauseCore/`
  - 可測試的領域邏輯（提醒、會議判斷、統計、設定、持久化）
- `Tests/EyePauseCoreTests/`
  - 針對核心邏輯的單元測試

## 快速理解建議順序

1. `Package.swift`（target 與依賴）
2. `Sources/EyePauseApp/EyePauseApp.swift`（啟動入口）
3. `Sources/EyePauseApp/AppModel.swift`（UI 與 Core 的協調核心）
4. `Sources/EyePauseCore/ReminderEngine.swift`（提醒狀態機）
5. `Sources/EyePauseCore/StatsStore.swift`、`Persistence.swift`（統計與資料保存）
