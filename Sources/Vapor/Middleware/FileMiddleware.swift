/// Serves static files from a public directory.
///
///     middlewareConfig = MiddlewareConfig()
///     middlewareConfig.use(FileMiddleware.self)
///     services.register(middlewareConfig)
///
/// `FileMiddleware` will default to `DirectoryConfig`'s working directory with `"/Public"` appended.
public final class FileMiddleware: Middleware {
    /// The public directory.
    /// - note: Must end with a slash.
    private let publicDirectory: String
    
    private let fileio: FileIO

    /// Creates a new `FileMiddleware`.
    public init(publicDirectory: String, fileio: FileIO) {
        self.publicDirectory = publicDirectory.hasSuffix("/") ? publicDirectory : publicDirectory + "/"
        self.fileio = fileio
    }

    /// See `Middleware`.
    public func respond(to req: HTTPRequestContext, chainingTo next: Responder) -> EventLoopFuture<HTTPResponse> {
        // make a copy of the path
        var path = req.http.url.path

        // path must be relative.
        while path.hasPrefix("/") {
            path = String(path.dropFirst())
        }

        // protect against relative paths
        guard !path.contains("../") else {
            return req.eventLoop.makeFailedFuture(error: Abort(.forbidden))
        }

        // create absolute file path
        let filePath = publicDirectory + path

        // check if file exists and is not a directory
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue else {
            return next.respond(to: req)
        }

        // stream the file
        let res = self.fileio.chunkedResponse(file: filePath, for: req.http)
        return req.eventLoop.makeSucceededFuture(result: res)
    }
}
