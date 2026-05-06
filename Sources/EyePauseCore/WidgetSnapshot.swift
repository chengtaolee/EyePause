import Foundation

public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public var nextBreakAt: Date?
    public var status: String
    public var updatedAt: Date

    public init(nextBreakAt: Date?, status: String, updatedAt: Date = Date()) {
        self.nextBreakAt = nextBreakAt
        self.status = status
        self.updatedAt = updatedAt
    }
}

public struct WidgetSnapshotStore {
    public static let appGroupIdentifier = "group.com.eyepause.shared"

    private let key: String
    private let store: KeyValueStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        key: String = "EyePause.widgetSnapshot.v1",
        store: KeyValueStore = UserDefaultsStore(
            defaults: UserDefaults(suiteName: appGroupIdentifier) ?? .standard
        )
    ) {
        self.key = key
        self.store = store
    }

    public func load() -> WidgetSnapshot? {
        guard let data = store.data(forKey: key) else {
            return nil
        }

        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    public func save(_ snapshot: WidgetSnapshot) throws {
        let data = try encoder.encode(snapshot)
        store.set(data, forKey: key)
    }
}
