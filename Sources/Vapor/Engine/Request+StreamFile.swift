import Bits
import Foundation

extension Request {
    /// If you are simply looking to serve files from your public directory,
    /// it may be useful to look at 'FileMiddleware' instead.
    ///
    /// Use this to initialize a file response for the exact file path.
    /// If using from a public folder for example, the file name should be appended
    /// to the public directory, ie: `drop.publicDir + "myFile.cool"`
    ///
    /// If none match represents an ETag that will be used to check if the file has
    /// changed since the last load by the client. This allows clients like browsers
    /// to cache their files and avoid downloading resources unnecessarily.
    /// Most often calculated w/
    /// https://tools.ietf.org/html/rfc7232#section-3.2
    ///
    /// For an example of how this is used, look at 'FileMiddleware'
    public func streamFile(at path: String) throws -> Response {
        let reader = try eventLoop.make(FileReader.self, for: Request.self)
        let res = makeResponse()

        guard
            let attributes = try? FileManager.default.attributesOfItem(atPath: path),
            let modifiedAt = attributes[.modificationDate] as? Date,
            let fileSize = attributes[.size] as? NSNumber
        else {
            throw Abort(.internalServerError)
        }

        var headers: [HTTPHeaders.Name: String] = [:]

        // Generate ETag value, "HEX value of last modified date" + "-" + "file size"
        let fileETag = "\(modifiedAt.timeIntervalSince1970)-\(fileSize.intValue)"
        headers[.eTag] = fileETag

        // Check if file has been cached already and return NotModified response if the etags match
        if fileETag == http.headers[.ifNoneMatch] {
            throw Abort(.notModified)
        }

        // Set Content-Type header based on the media type
        // Only set Content-Type if file not modified and returned above.
        if
            let fileExtension = path.components(separatedBy: ".").last,
            let type = MediaType.from(fileExtension: fileExtension)
        {
            res.http.mediaType = type
        }

        res.http.body = HTTPBody(
            chunked: reader.read(at: path, chunkSize: 2048)
        )
        return res
    }
}

