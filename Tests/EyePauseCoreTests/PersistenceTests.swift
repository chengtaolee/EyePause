import Foundation
import XCTest
@testable import EyePauseCore

final class PersistenceTests: XCTestCase {
    func testSnapshotRoundTripsThroughKeyValueStore() throws {
        let memory = MemoryKeyValueStore()
        let persistence = PersistenceStore(key: "test", store: memory)
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        stats.recordCompletedBreak(now: Date(timeIntervalSince1970: 0))
        let snapshot = AppSnapshot(
            settings: SettingsStore(interval: .thirtyMinutes, isForcedModeEnabled: true),
            stats: stats
        )

        try persistence.save(snapshot)
        let loaded = persistence.load()

        XCTAssertEqual(loaded.settings.interval, .thirtyMinutes)
        XCTAssertTrue(loaded.settings.isForcedModeEnabled)
        XCTAssertEqual(loaded.stats.today.completedCount, 1)
    }

    func testSaveWritesVersionedEnvelope() throws {
        let memory = MemoryKeyValueStore()
        let key = "test"
        let persistence = PersistenceStore(key: key, store: memory)

        try persistence.save(AppSnapshot())

        let data = try XCTUnwrap(memory.data(forKey: key))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["schemaVersion"] as? Int, 2)
        XCTAssertNotNil(json["snapshot"])
    }

    func testLoadUnversionedSnapshotDefaultsMissingOnboardingToIncomplete() throws {
        let memory = MemoryKeyValueStore()
        let key = "test"
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        stats.recordCompletedBreak(now: Date(timeIntervalSince1970: 0))
        let legacyData = try legacySnapshotData(
            settings: SettingsStore(interval: .thirtyMinutes, isForcedModeEnabled: true),
            stats: stats
        )
        memory.set(legacyData, forKey: key)
        let persistence = PersistenceStore(key: key, store: memory)

        let loaded = persistence.load()

        XCTAssertEqual(loaded.settings.interval, .thirtyMinutes)
        XCTAssertTrue(loaded.settings.isForcedModeEnabled)
        XCTAssertFalse(loaded.settings.hasCompletedOnboarding)
        XCTAssertEqual(loaded.stats.today.completedCount, 1)
    }

    func testLoadSchemaOneEnvelopeDefaultsMissingOnboardingToIncomplete() throws {
        let memory = MemoryKeyValueStore()
        let key = "test"
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        stats.recordSkippedBreak(now: Date(timeIntervalSince1970: 0))
        let legacySnapshot = try legacySnapshotObject(
            settings: SettingsStore(interval: .fortyFiveMinutes, launchAtLoginEnabled: true),
            stats: stats
        )
        let envelope: [String: Any] = [
            "schemaVersion": 1,
            "snapshot": legacySnapshot
        ]
        memory.set(try JSONSerialization.data(withJSONObject: envelope), forKey: key)
        let persistence = PersistenceStore(key: key, store: memory)

        let loaded = persistence.load()

        XCTAssertEqual(loaded.settings.interval, .fortyFiveMinutes)
        XCTAssertTrue(loaded.settings.launchAtLoginEnabled)
        XCTAssertFalse(loaded.settings.hasCompletedOnboarding)
        XCTAssertEqual(loaded.stats.today.skippedCount, 1)
    }

    func testSaveEncodingFailureDoesNotOverwriteExistingSnapshot() throws {
        enum EncodingFailure: Error {
            case failed
        }

        let memory = MemoryKeyValueStore()
        let key = "test"
        let existingData = Data("existing".utf8)
        memory.set(existingData, forKey: key)
        let persistence = PersistenceStore(
            key: key,
            store: memory,
            encode: { _ in throw EncodingFailure.failed }
        )

        XCTAssertThrowsError(try persistence.save(AppSnapshot()))
        XCTAssertEqual(memory.data(forKey: key), existingData)
    }

    private func legacySnapshotData(settings: SettingsStore, stats: StatsStore) throws -> Data {
        try JSONSerialization.data(withJSONObject: legacySnapshotObject(settings: settings, stats: stats))
    }

    private func legacySnapshotObject(settings: SettingsStore, stats: StatsStore) throws -> [String: Any] {
        let data = try JSONEncoder().encode(AppSnapshot(settings: settings, stats: stats))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var settingsJson = try XCTUnwrap(json["settings"] as? [String: Any])
        settingsJson.removeValue(forKey: "hasCompletedOnboarding")
        json["settings"] = settingsJson
        return json
    }
}

private final class MemoryKeyValueStore: KeyValueStore {
    private var values: [String: Data] = [:]

    func data(forKey key: String) -> Data? {
        values[key]
    }

    func set(_ value: Data?, forKey key: String) {
        values[key] = value
    }
}
