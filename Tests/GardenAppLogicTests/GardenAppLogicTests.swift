import XCTest
import SwiftUI
import Security
import GardenCore
@testable import GardenAppLogic

final class GardenAppLogicTests: XCTestCase {
    @MainActor final class TimeSource {
        var date = Date(timeIntervalSince1970: 2_000_000)
        var uptime: TimeInterval = 10_000
        func advance(_ seconds: TimeInterval) { date += seconds; uptime += seconds }
    }
    @MainActor private func makeStore(bank: [Question]? = nil, allowsDrafts: Bool = true, time: TimeSource = TimeSource()) throws -> (GardenStore, URL, TimeSource) {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let bankURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appending(path: "App/questions.json")
        let questions = try bank ?? JSONDecoder().decode([Question].self, from: Data(contentsOf: bankURL))
        let url = directory.appending(path: "state.json")
        return (GardenStore(url: url, bank: questions, allowsDrafts: allowsDrafts, now: { time.date }, uptime: { time.uptime }), url, time)
    }
    @MainActor func testOfflineRoundFeedbackRecapAndRelaunch() async throws {
        let (store, url, time) = try makeStore()
        store.tick(); store.next(); store.answer(.unsure) // unconfigured actions do nothing
        store.setup(grade: 0); store.start()
        XCTAssertNotNil(store.state.round?.pending)
        for index in 0..<10 {
            let question = try XCTUnwrap(store.state.round?.pending)
            if index == 0 { store.state.progress[question.subject] = nil }
            store.answer(index == 0 ? .unsure : .choice(question.correct))
            store.answer(.unsure) // feedback cannot submit another attempt
            XCTAssertEqual(store.state.history.count, index + 1)
            if index == 9 {
                let restored = GardenStore(url: url, bank: store.bank, now: { time.date }, uptime: { time.uptime })
                XCTAssertFalse(restored.recap)
                XCTAssertNotNil(restored.state.round?.response)
            }
            store.next()
        }
        XCTAssertTrue(store.recap); XCTAssertEqual(store.state.round?.endReason, .completed)
        let restored = GardenStore(url: url, bank: store.bank, now: { time.date }, uptime: { time.uptime })
        XCTAssertTrue(restored.recap)
        XCTAssertEqual(restored.state.history.count, 10)
        restored.start(); XCTAssertEqual(restored.state.round?.answers.count, 0)
    }
    @MainActor func testForegroundPauseFirmCapAndPersistentBreak() async throws {
        let (store, url, time) = try makeStore()
        store.setup(grade: 0); store.start()
        time.advance(100); store.parentOpen = true; store.tick()
        XCTAssertEqual(store.state.clock.used, 100)
        time.advance(300); store.tick(); XCTAssertEqual(store.state.clock.used, 100)
        store.parentUnlocked = true
        store.lifecycle(.background)
        XCTAssertFalse(store.parentUnlocked); XCTAssertFalse(store.parentOpen)
        time.advance(100); store.lifecycle(.inactive)
        XCTAssertEqual(store.state.clock.used, 100)
        store.lifecycle(.active)
        time.advance(1100); store.answer(.unsure)
        XCTAssertTrue(store.blocked); XCTAssertTrue(store.state.history.isEmpty)
        XCTAssertEqual(store.state.round?.endReason, .sessionLimit)
        store.next(); store.start(); XCTAssertTrue(store.blocked)
        let restored = GardenStore(url: url, bank: store.bank, now: { time.date }, uptime: { time.uptime })
        XCTAssertTrue(restored.blocked)
        restored.setup(grade: 5); XCTAssertTrue(restored.blocked)
        time.advance(1799); restored.tick(); XCTAssertTrue(restored.blocked)
        time.advance(1); restored.tick(); XCTAssertFalse(restored.blocked)
        restored.start(); XCTAssertNotNil(restored.state.round?.pending)
    }
    @MainActor func testMissingContentAndReleaseUpgrade() async throws {
        let (empty, _, _) = try makeStore(bank: [])
        empty.setup(grade: 0); empty.start()
        XCTAssertTrue(empty.recap); XCTAssertEqual(empty.state.round?.endReason, .contentUnavailable)
        let (debug, url, time) = try makeStore()
        debug.setup(grade: 0); debug.start(); debug.answer(.unsure)
        let release = GardenStore(url: url, bank: debug.bank, allowsDrafts: false, now: { time.date }, uptime: { time.uptime })
        XCTAssertNil(release.state.round); XCTAssertEqual(release.state.history.count, 1)
        release.start(); XCTAssertEqual(release.state.round?.endReason, .contentUnavailable)
        // Exercise the production clock and absent-resource loader without real app data.
        let defaults = GardenStore(url: url.deletingLastPathComponent().appending(path: "new.json"))
        XCTAssertTrue(defaults.bank.isEmpty); defaults.setup(grade: 0); defaults.tick()
        XCTAssertGreaterThan(defaults.state.clock.lastUptime ?? 0, 0)
    }
    @MainActor func testCorruptStateAndWriteFailuresPausePlay() async throws {
        let (original, url, time) = try makeStore()
        try Data("not JSON".utf8).write(to: url)
        let corrupted = GardenStore(url: url, bank: [], now: { time.date }, uptime: { time.uptime })
        XCTAssertNotNil(corrupted.error); XCTAssertFalse(corrupted.wantsPlay)
        corrupted.start(); XCTAssertNil(corrupted.state.round)
        let unavailable = url.appending(path: "cannot-create/state.json") // parent is a file
        let failing = GardenStore(url: unavailable, bank: original.bank)
        failing.setup(grade: 0); XCTAssertNotNil(failing.error)
        failing.answer(.unsure); failing.next(); failing.start()
        XCTAssertTrue(failing.state.history.isEmpty)
    }
    private func withKeychain(_ body: (String) throws -> Void) throws {
        let service = "org.curiositygarden.tests.\(UUID().uuidString)"
        defer { SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: service] as CFDictionary) }
        try body(service)
    }
    func testPINCreationVerificationUpdateAndCooldown() throws {
        try withKeychain { service in
            XCTAssertFalse(ParentPIN.hasPIN(service: service))
            for invalid in ["", "123", "abcdef", "１２３４５６"] { XCTAssertFalse(ParentPIN.create(invalid, service: service)) }
            XCTAssertTrue(ParentPIN.create("314159", service: service))
            XCTAssertTrue(ParentPIN.hasPIN(service: service))
            XCTAssertFalse(ParentPIN.verify("", service: service))
            let now = Date(timeIntervalSince1970: 2_000_000)
            XCTAssertTrue(ParentPIN.verify("314159", service: service, now: now))
            for _ in 0..<5 { XCTAssertFalse(ParentPIN.verify("000000", service: service, now: now)) }
            XCTAssertFalse(ParentPIN.verify("314159", service: service, now: now + 299))
            XCTAssertTrue(ParentPIN.verify("314159", service: service, now: now + 300))
            XCTAssertTrue(ParentPIN.create("271828", service: service))
            XCTAssertTrue(ParentPIN.verify("271828", service: service, now: now))
        }
    }
    func testPINRejectsCorruptCredential() throws {
        try withKeychain { service in
            let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "parent", kSecValueData as String: Data("broken".utf8)]
            XCTAssertEqual(SecItemAdd(query as CFDictionary, nil), errSecSuccess)
            XCTAssertFalse(ParentPIN.hasPIN(service: service))
            XCTAssertFalse(ParentPIN.verify("314159", service: service))
        }
    }
}
