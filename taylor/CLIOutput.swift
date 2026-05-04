//
//  CLIOutput.swift
//  taylor
//

import Foundation

/// Abstraction over stdout/stderr so command handlers are independently testable.
protocol CLIOutput {
    func write(_ message: String)
    func writeError(_ message: String)
}

/// Default implementation that writes to real stdout/stderr.
struct StandardOutput: CLIOutput {
    func write(_ message: String) {
        print(message)
    }

    func writeError(_ message: String) {
        fputs(message + "\n", stderr)
    }
}
