import XCTest
import LocalAuthentication
import Security
import SwiftUI
import GardenCore
@testable import GardenAppLogic

// The system prompt itself is exercised on devices. This stub supplies its
// asynchronous replies, including replies that arrive after cancellation.
private final class AuthenticationContextStub: LAContext, @unchecked Sendable {
    private let lock = NSLock()
    private var pendingReply: (@Sendable (Bool, Error?) -> Void)?
    private var requestedPolicies: [LAPolicy] = []
    private var invalidations = 0
    var available = true
    var immediateReply: Bool? = true
    var replyError: Error?
    var onEvaluation: (@Sendable () -> Void)?
    var policies: [LAPolicy] { lock.withLock { requestedPolicies } }
    var invalidated: Bool { lock.withLock { invalidations > 0 } }
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        lock.withLock { requestedPolicies.append(policy) }
        return available
    }
    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping @Sendable (Bool, Error?) -> Void) {
        lock.withLock { requestedPolicies.append(policy); pendingReply = reply }
        onEvaluation?()
        if let immediateReply { complete(immediateReply, error: replyError) }
    }
    override func invalidate() { lock.withLock { invalidations += 1 } }
    func complete(_ success: Bool, error: Error? = nil) {
        let reply = lock.withLock { let reply = pendingReply; pendingReply = nil; return reply }
        reply?(success, error)
    }
}

@MainActor final class ParentPINRecoveryTests: XCTestCase {
    private func makeStore(context: AuthenticationContextStub, createPIN: Bool = true) throws -> (GardenStore, String, URL, GardenAppLogicTests.TimeSource) {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let service = "org.curiositygarden.recovery-tests.\(UUID().uuidString)"
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
            SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: service] as CFDictionary)
        }
        if createPIN { XCTAssertTrue(ParentPIN.create("314159", service: service)) }
        let time = GardenAppLogicTests.TimeSource()
        let question = Question(id: "recovery-test", subject: .math, level: 0, readingGrade: 0,
                                prompt: "One plus one?", choices: ["Two", "Three"], correct: 0,
                                explanation: "One and one make two.", source: "Original test fixture")
        let url = directory.appending(path: "state.json")
        let store = GardenStore(url: url, bank: [question], now: { time.date }, uptime: { time.uptime },
                                authenticationContext: { context }, pinService: service)
        store.parentOpen = true
        return (store, service, url, time)
    }
    private func beginRecovery(_ store: GardenStore, context: AuthenticationContextStub) async -> Task<GardenStore.PINRecoveryResult, Never> {
        let started = expectation(description: "System authentication requested")
        context.onEvaluation = { started.fulfill() }
        let task = Task { await store.recoverParentPIN(replacement: "271828", confirmation: "271828") }
        let result = await XCTWaiter.fulfillment(of: [started], timeout: 3)
        XCTAssertEqual(result, .completed)
        return task
    }
    func testSuccessfulRecoveryReplacesPINWithoutUnlockingOrChangingProgress() async throws {
        let context = AuthenticationContextStub()
        let (store, service, url, time) = try makeStore(context: context)
        store.parentOpen = false; store.setup(grade: 0); store.start()
        XCTAssertNil(store.error)
        time.advance(120); store.answer(.unsure)
        store.parentOpen = true; store.tick()
        let before = try Data(contentsOf: url)
        // Recovery is also available during the old PIN's cooldown.
        for _ in 0..<5 { XCTAssertFalse(ParentPIN.verify("000000", service: service, now: time.date)) }
        let result = await store.recoverParentPIN(replacement: "271828", confirmation: "271828")
        XCTAssertEqual(result, .success)
        XCTAssertEqual(context.policies, [.deviceOwnerAuthentication, .deviceOwnerAuthentication])
        XCTAssertTrue(context.invalidated); XCTAssertFalse(store.recoveringPIN)
        XCTAssertFalse(store.parentUnlocked); XCTAssertTrue(store.parentOpen)
        XCTAssertFalse(ParentPIN.verify("314159", service: service, now: time.date))
        XCTAssertTrue(ParentPIN.verify("271828", service: service, now: time.date))
        XCTAssertEqual(try Data(contentsOf: url), before)
        let restored = GardenStore(url: url, bank: store.bank, now: { time.date }, uptime: { time.uptime })
        XCTAssertEqual(restored.state.history.count, 1)
        XCTAssertEqual(restored.state.clock.used, 120)
        XCTAssertEqual(restored.state.progress[.math]?.level, store.state.progress[.math]?.level)
        XCTAssertFalse(restored.parentUnlocked)
    }
    func testRecoveryPreservesAnExhaustedSessionAndBreakAcrossRelaunch() async throws {
        let context = AuthenticationContextStub()
        let (store, _, url, time) = try makeStore(context: context)
        store.parentOpen = false; store.setup(grade: 0); store.start()
        time.advance(1200); store.tick()
        XCTAssertTrue(store.blocked)
        store.parentOpen = true; store.tick()
        let result = await store.recoverParentPIN(replacement: "271828", confirmation: "271828")
        XCTAssertEqual(result, .success); XCTAssertTrue(store.blocked)
        let restored = GardenStore(url: url, bank: store.bank, now: { time.date }, uptime: { time.uptime })
        XCTAssertTrue(restored.blocked)
        time.advance(1799); restored.tick(); XCTAssertTrue(restored.blocked)
        time.advance(1); restored.tick(); XCTAssertFalse(restored.blocked)
    }
    func testInvalidReplacementNeverStartsDeviceAuthentication() async throws {
        let context = AuthenticationContextStub()
        let (store, service, _, _) = try makeStore(context: context)
        for invalid in ["", "123", "abcdef", "１２３４５６"] {
            let result = await store.recoverParentPIN(replacement: invalid, confirmation: invalid)
            XCTAssertEqual(result, .invalidPIN)
        }
        let mismatch = await store.recoverParentPIN(replacement: "271828", confirmation: "314159")
        XCTAssertEqual(mismatch, .invalidPIN)
        XCTAssertTrue(context.policies.isEmpty)
        XCTAssertTrue(ParentPIN.verify("314159", service: service))
    }
    func testMissingPINAndUnavailableDeviceAuthenticationFailClosed() async throws {
        let context = AuthenticationContextStub()
        let (missing, _, _, _) = try makeStore(context: context, createPIN: false)
        let noPIN = await missing.recoverParentPIN(replacement: "271828", confirmation: "271828")
        XCTAssertEqual(noPIN, .saveFailed); XCTAssertTrue(context.policies.isEmpty)
        let (store, service, _, _) = try makeStore(context: context)
        context.available = false
        let unavailable = await store.recoverParentPIN(replacement: "271828", confirmation: "271828")
        XCTAssertEqual(unavailable, .unavailable)
        XCTAssertEqual(context.policies, [.deviceOwnerAuthentication])
        XCTAssertTrue(context.invalidated); XCTAssertFalse(store.recoveringPIN)
        XCTAssertTrue(ParentPIN.verify("314159", service: service))
        XCTAssertFalse(store.parentUnlocked)
    }
    func testRejectedOrCancelledAuthenticationPreservesPINAndItsCooldown() async throws {
        for error in [nil, LAError(.userCancel), LAError(.authenticationFailed)] as [Error?] {
            let context = AuthenticationContextStub(); context.immediateReply = false; context.replyError = error
            let (store, service, _, time) = try makeStore(context: context)
            for _ in 0..<5 { XCTAssertFalse(ParentPIN.verify("000000", service: service, now: time.date)) }
            let result = await store.recoverParentPIN(replacement: "271828", confirmation: "271828")
            XCTAssertEqual(result, .cancelled)
            XCTAssertFalse(ParentPIN.verify("314159", service: service, now: time.date))
            XCTAssertTrue(ParentPIN.verify("314159", service: service, now: time.date + 300))
            XCTAssertFalse(store.parentUnlocked); XCTAssertFalse(store.recoveringPIN)
            XCTAssertTrue(context.invalidated)
        }
    }
    func testAuthenticationPromptMayTemporarilyMakeAppInactive() async throws {
        let context = AuthenticationContextStub(); context.immediateReply = nil
        let (store, service, _, time) = try makeStore(context: context)
        store.setup(grade: 0)
        let task = await beginRecovery(store, context: context)
        XCTAssertTrue(store.recoveringPIN)
        store.lifecycle(.inactive)
        XCTAssertTrue(store.parentOpen); XCTAssertFalse(store.parentUnlocked)
        time.advance(30); store.tick(); XCTAssertEqual(store.state.clock.used, 0)
        context.complete(true)
        let result = await task.value
        XCTAssertEqual(result, .success)
        XCTAssertTrue(ParentPIN.verify("271828", service: service))
        store.lifecycle(.active)
        XCTAssertTrue(store.parentOpen); XCTAssertFalse(store.parentUnlocked)
    }
    func testBackgroundOrDismissalRejectsLateSuccessfulAuthentication() async throws {
        for background in [true, false] {
            let context = AuthenticationContextStub(); context.immediateReply = nil
            let (store, service, _, _) = try makeStore(context: context)
            let task = await beginRecovery(store, context: context)
            if background { store.lifecycle(.background) } else { store.closeParent() }
            XCTAssertTrue(context.invalidated); XCTAssertFalse(store.parentOpen)
            // Reopening before the reply must not revive the old attempt.
            store.lifecycle(.active); store.parentOpen = true
            context.complete(true)
            let result = await task.value
            XCTAssertEqual(result, .cancelled)
            XCTAssertTrue(ParentPIN.verify("314159", service: service))
            XCTAssertFalse(store.parentUnlocked); XCTAssertFalse(store.recoveringPIN)
        }
    }
    func testRecoveryRequiresVisibleLockedParentAreaAndRejectsConcurrentAttempt() async throws {
        let context = AuthenticationContextStub(); context.immediateReply = nil
        let (store, _, _, _) = try makeStore(context: context)
        store.parentOpen = false
        let closed = await store.recoverParentPIN(replacement: "271828", confirmation: "271828")
        XCTAssertEqual(closed, .cancelled)
        store.parentOpen = true; store.parentUnlocked = true
        let unlocked = await store.recoverParentPIN(replacement: "271828", confirmation: "271828")
        XCTAssertEqual(unlocked, .cancelled)
        store.parentUnlocked = false; store.active = false
        let inactive = await store.recoverParentPIN(replacement: "271828", confirmation: "271828")
        XCTAssertEqual(inactive, .cancelled)
        store.active = true
        let task = await beginRecovery(store, context: context)
        let duplicate = await store.recoverParentPIN(replacement: "123456", confirmation: "123456")
        XCTAssertEqual(duplicate, .cancelled)
        XCTAssertEqual(context.policies.count, 2)
        context.complete(true)
        let result = await task.value
        XCTAssertEqual(result, .success)
    }
    func testOldReplyCannotCancelOrAuthorizeANewerRecoveryAttempt() async throws {
        let oldContext = AuthenticationContextStub(); oldContext.immediateReply = nil
        let newContext = AuthenticationContextStub(); newContext.immediateReply = nil
        let (original, service, url, _) = try makeStore(context: oldContext)
        var contexts = [oldContext, newContext]
        let store = GardenStore(url: url, bank: original.bank, authenticationContext: { contexts.removeFirst() }, pinService: service)
        store.parentOpen = true
        let oldTask = await beginRecovery(store, context: oldContext)
        store.closeParent(); store.parentOpen = true
        let newTask = await beginRecovery(store, context: newContext)
        oldContext.complete(true)
        let oldResult = await oldTask.value
        XCTAssertEqual(oldResult, .cancelled)
        XCTAssertTrue(store.recoveringPIN); XCTAssertFalse(newContext.invalidated)
        XCTAssertTrue(ParentPIN.verify("314159", service: service))
        newContext.complete(true)
        let newResult = await newTask.value
        XCTAssertEqual(newResult, .success)
        XCTAssertFalse(store.recoveringPIN); XCTAssertTrue(newContext.invalidated)
        XCTAssertTrue(ParentPIN.verify("271828", service: service))
    }
    func testCancelledTaskCannotReplacePINAfterAuthenticationSucceeds() async throws {
        let context = AuthenticationContextStub(); context.immediateReply = nil
        let (store, service, _, _) = try makeStore(context: context)
        let task = await beginRecovery(store, context: context)
        task.cancel(); context.complete(true)
        let result = await task.value
        XCTAssertEqual(result, .cancelled)
        XCTAssertTrue(ParentPIN.verify("314159", service: service))
        XCTAssertFalse(store.parentUnlocked); XCTAssertFalse(store.recoveringPIN)
        XCTAssertTrue(context.invalidated)
    }
    func testRecoveryMessagesDescribeResultWithoutExposingCredentials() {
        XCTAssertEqual(GardenStore.PINRecoveryResult.success.message, "PIN reset. Enter your new PIN to unlock.")
        XCTAssertTrue(GardenStore.PINRecoveryResult.invalidPIN.message.contains("matching six-digit"))
        XCTAssertTrue(GardenStore.PINRecoveryResult.unavailable.message.contains("device passcode"))
        XCTAssertTrue(GardenStore.PINRecoveryResult.cancelled.message.contains("PIN not changed"))
        XCTAssertTrue(GardenStore.PINRecoveryResult.saveFailed.message.contains("could not be saved"))
    }
}
