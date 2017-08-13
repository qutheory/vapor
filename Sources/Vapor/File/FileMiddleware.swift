import Foundation
import HTTP
import libc
import Service
import Routing

/// Servers files from the supplied public directory
/// on not found errors.
public final class FileMiddleware: Middleware {
    private var publicDir: String
    private let loader: FileManager
    private let chunkSize: Int

    public init(publicDir: String, chunkSize: Int? = nil) {
        self.loader = FileManager()
        // Remove last "/" from the publicDir if present, so we can directly append uri path from the request.
        self.publicDir = publicDir.finished(with: "/")
        self.chunkSize = chunkSize ?? 32_768 // 2^15
    }

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            return try next.respond(to: request)
        } catch RouterError.missingRoute {
            // Check in file system
            var path = request.uri.path
            guard !path.contains("../") else { throw HTTP.Status.forbidden }
            if path.hasPrefix("/") {
                path = String(path.characters.dropFirst())
            }
            let filePath = publicDir + path
            let ifNoneMatch = request.headers["If-None-Match"]
            return try Response(filePath: filePath, ifNoneMatch: ifNoneMatch, chunkSize: chunkSize)
        }
    }
}

// MARK: Service

extension FileMiddleware: ServiceType {
    /// See Service.serviceName
    public static var serviceName: String {
        return "file"
    }

    /// See Service.serviceSupports
    public static var serviceSupports: [Any.Type] {
        return [Middleware.self]
    }

    /// See Service.make
    public static func makeService(for container: Container) throws -> FileMiddleware? {
        let dirs = try container.make(WorkingDirectory.self)
        return FileMiddleware(publicDir: dirs.publicDir)
    }
}
