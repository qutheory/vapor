import Async
import Core
import Dispatch
import Foundation
import Service

public final class LeafProvider: Provider {
    /// See Service.Provider.repositoryName
    public static let repositoryName = "leaf"

    public init() {}

    /// See Service.Provider.Register
    public func register(_ services: inout Services) throws {
        services.register { container -> LeafConfig in
            let dir = try container.make(DirectoryConfig.self, for: LeafRenderer.self)
            return LeafConfig(viewsDir: dir.workDir + "Resources/Views")
        }
    }

    /// See Service.Provider.boot
    public func boot(_ context: Context) throws { }
}

fileprivate let leafRendererKey = "leaf:renderer"

// MARK: View

public struct View: Codable {
    /// The view's data.
    public let data: Data

    /// Create a new View
    public init(data: Data) {
        self.data = data
    }

    /// See Encodable.encode
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }

    /// See Decodable.decode
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(data: container.decode(Data.self))
    }
}

public protocol ViewRenderer {
    func make(_ path: String, context: Encodable, on worker: Worker) throws -> Future<View>
}

extension ViewRenderer {
    /// See ViewRenderer.make
    public func make(_ path: String, _ context: [String: Encodable], on worker: Worker) throws -> Future<View> {
        return try make(path, context: context, on: worker)
    }
}
