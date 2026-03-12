import Foundation

enum AppLogger {
    static func log(_ message: String) {
        #if DEBUG
        print("[LocalAI] \(message)")
        #endif
    }
}
