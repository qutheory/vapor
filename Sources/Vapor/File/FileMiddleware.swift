import Foundation
import HTTP
import libc

/// Servers files from the supplied public directory
/// on not found errors.
public final class FileMiddleware: Middleware {

    private var publicDir: String
    private let loader = DataFile()
    private let chunkSize: Int

    public init(publicDir: String, chunkSize: Int? = nil) {
        // Remove last "/" from the publicDir if present, so we can directly append uri path from the request.
        self.publicDir = publicDir.finished(with: "/")
        self.chunkSize = chunkSize ?? 32_768 // 2^15
    }

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            return try next.respond(to: request)
        } catch let error as AbortError where error.status == .notFound {
            // Check in file system
            var path = request.uri.path
            guard !path.contains("../") else { throw HTTP.Status.forbidden }
            if path.hasPrefix("/") {
                path = String(path.characters.dropFirst())
            }
            let filePath = publicDir + path
            let ifNoneMatch = request.headers["If-None-Match"]

            do {
                return try Response(filePath: filePath, ifNoneMatch: ifNoneMatch, chunkSize: chunkSize)
            } catch let newError as AbortError where newError.status == .notFound {
                // throw original error, so custom reason is passed to client
                throw error
            }
        }
    }
}
