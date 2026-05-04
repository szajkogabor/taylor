//
//  CLIError.swift
//  taylor
//

import Foundation

enum CLIError: Error {
    /// Subcommand-level usage error (invalid arguments, missing required fields)
    case usageError(String)
    /// EventKit store is not accessible
    case serviceUnavailable(String)
    /// Failed to persist a new reminder
    case cannotCreate(String)
    /// Failed to fetch / read reminders
    case readFailure(String)
    /// EventKit authorization denied or restricted
    case permissionDenied
    /// Runtime configuration error (e.g. unknown reminders list)
    case configError(String)
    /// Requested item not found
    case notFound(String)
    /// Unclassified runtime failure
    case unknown(String)

    /// POSIX-style exit code for this error.
    var exitCode: Int32 {
        switch self {
        case .usageError:        return 64
        case .serviceUnavailable: return 69
        case .cannotCreate:      return 73
        case .readFailure:       return 74
        case .permissionDenied:  return 77
        case .configError:       return 78
        case .notFound:          return 1
        case .unknown:           return 1
        }
    }

    /// Human-readable error description.
    var message: String {
        switch self {
        case .usageError(let m):
            return "Usage error: \(m)"
        case .serviceUnavailable(let m):
            return "Service unavailable: \(m)"
        case .cannotCreate(let m):
            return "Cannot create reminder: \(m)"
        case .readFailure(let m):
            return "Read failure: \(m)"
        case .permissionDenied:
            return "Permission denied. Please grant Reminders access in:\n  System Settings → Privacy & Security → Reminders"
        case .configError(let m):
            return "Configuration error: \(m)"
        case .notFound(let m):
            return "Not found: \(m)"
        case .unknown(let m):
            return "Error: \(m)"
        }
    }
}
