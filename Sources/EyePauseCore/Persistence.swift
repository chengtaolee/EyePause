import Foundation

public struct AppSnapshot: Codable, Equatable, Sendable {
    public var settings: SettingsStore
    public var stats: StatsStore

    public init(settings: SettingsStore = SettingsStore(), stats: StatsStore = StatsStore()) {
        self.settings = settings
        self.stats = stats
    }
}

public protocol KeyValueStore {
    func data(forKey key: String) -> Data?
    func set(_ value: Data?, forKey key: String)
}

public final class UserDefaultsStore: KeyValueStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    public func set(_ value: Data?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}

public struct PersistenceStore {
    private struct VersionedSnapshot: Codable {
        var schemaVersion: Int
        var snapshot: AppSnapshot
    }

    private let key: String
    private let store: KeyValueStore
    private let encodeSnapshot: (AppSnapshot) throws -> Data
    private let decoder = JSONDecoder()
    private static let currentSchemaVersion = 2

    public init(
        key: String = "EyePause.snapshot.v1",
        store: KeyValueStore = UserDefaultsStore(),
        encode: ((AppSnapshot) throws -> Data)? = nil
    ) {
        self.key = key
        self.store = store
        self.encodeSnapshot = encode ?? Self.encodeVersionedSnapshot
    }

    public func load() -> AppSnapshot {
        guard let data = store.data(forKey: key) else {
            return AppSnapshot()
        }

        do {
            let versioned = try decoder.decode(VersionedSnapshot.self, from: data)
            guard versioned.schemaVersion == Self.currentSchemaVersion else {
                NSLog("EyePause unsupported persistence schema version: \(versioned.schemaVersion)")
                return AppSnapshot()
            }
            return versioned.snapshot
        } catch {
            do {
                let snapshot = try decoder.decode(AppSnapshot.self, from: data)
                NSLog("EyePause loaded legacy persistence snapshot without schema version.")
                return snapshot
            } catch {
                NSLog("EyePause failed to decode persistence snapshot: \(error.localizedDescription)")
                return AppSnapshot()
            }
        }
    }

    public func save(_ snapshot: AppSnapshot) throws {
        let data = try encodeSnapshot(snapshot)
        store.set(data, forKey: key)
    }

    private static func encodeVersionedSnapshot(_ snapshot: AppSnapshot) throws -> Data {
        try JSONEncoder().encode(VersionedSnapshot(schemaVersion: currentSchemaVersion, snapshot: snapshot))
    }
}
