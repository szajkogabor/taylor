//
//  AsyncRunner.swift
//  taylor
//
//  Bridges async/await code to synchronous ArgumentParser commands.
//  Keeps the main RunLoop spinning so EventKit callbacks can fire.
//

import Foundation

/// Runs an async throwing closure synchronously on the main RunLoop.
/// Keeps the run loop alive so EventKit callback-based APIs (fetchReminders) can fire.
func runAsyncAndWait(_ work: @escaping () async throws -> Void) throws {
    var thrownError: Error?
    var done = false

    Task { @MainActor in
        do { try await work() }
        catch { thrownError = error }
        done = true
    }

    while !done {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    }

    if let error = thrownError { throw error }
}
