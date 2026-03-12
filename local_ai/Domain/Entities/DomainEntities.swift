import Foundation

struct LocalModel: Equatable, Identifiable, Codable {
    enum Status: String, Codable {
        case notDownloaded
        case downloading
        case installed
        case active
    }

    let id: String
    let displayName: String
    let parameterSize: String
    let estimatedSizeInBytes: Int64
    let summary: String
    let supportsStreaming: Bool
    let minimumRAMInGB: Int
    let isCompatibleWithCurrentDevice: Bool
    var status: Status
    var downloadProgress: Double? = nil
}

struct ChatSession: Equatable, Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var title: String
    var activeModelID: String?
    var isPinned: Bool

    init(id: UUID, createdAt: Date, title: String, activeModelID: String?, isPinned: Bool = false) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.activeModelID = activeModelID
        self.isPinned = isPinned
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case title
        case activeModelID
        case isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        title = try container.decode(String.self, forKey: .title)
        activeModelID = try container.decodeIfPresent(String.self, forKey: .activeModelID)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(activeModelID, forKey: .activeModelID)
        try container.encode(isPinned, forKey: .isPinned)
    }
}

struct Message: Equatable, Identifiable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let sessionID: UUID
    let role: Role
    let content: String
    let createdAt: Date
}

struct GenerationConfig: Equatable, Codable {
    var temperature: Double
    var topP: Double
    var maxTokens: Int
    var contextLength: Int

    static let `default` = GenerationConfig(
        temperature: 0.7,
        topP: 0.9,
        maxTokens: 512,
        contextLength: 4096
    )
}

struct DownloadTaskInfo: Equatable, Identifiable, Codable {
    enum State: String, Codable {
        case queued
        case downloading
        case paused
        case completed
        case failed
        case canceled
    }

    let id: UUID
    let modelID: String
    let modelName: String
    var progress: Double
    var state: State
}

struct DeviceCapability: Equatable, Codable {
    let totalMemoryInGB: Int
    let availableDiskSpaceInBytes: Int64
    let supportsOnDeviceInference: Bool
}
