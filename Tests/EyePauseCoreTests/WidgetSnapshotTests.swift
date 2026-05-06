import Foundation
import XCTest
@testable import EyePauseCore

final class WidgetSnapshotTests: XCTestCase {
    func testWidgetSnapshotRoundTripsThroughKeyValueStore() throws {
        let memory = MemoryKeyValueStore()
        let store = WidgetSnapshotStore(key: "test", store: memory)
        let snapshot = WidgetSnapshot(
            nextBreakAt: Date(timeIntervalSince1970: 30 * 60),
            status: "Active",
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        try store.save(snapshot)

        XCTAssertEqual(store.load(), snapshot)
    }

    func testWidgetSnapshotLoadReturnsNilWhenMissing() {
        let memory = MemoryKeyValueStore()
        let store = WidgetSnapshotStore(key: "test", store: memory)

        XCTAssertNil(store.load())
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
