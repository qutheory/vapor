import HTTP

/// Keeps track of any (server or client's, remote or local) header table with entries
final class HeadersTable {
    /// A single table entry
    struct Entry {
        /// The header name, *must* be lowercased
        var name: Headers.Name
        
        /// The table index of this header
        var index: Int
        
        /// The associated value (usually empty)
        var value: String
        
        /// Creates a new header table entry
        init(index: Int = 0, name: Headers.Name, value: String = "") {
            self.index = index
            self.name = name
            self.value = value
        }
    }
    
    /// The maximum size of the headers table as specified here:
    ///
    /// http://httpwg.org/specs/rfc7541.html#rfc.section.4.1
    var tableSize: Int = 4_096
    
    /// The current size (cached)
    var currentTableSize = 0
    
    /// Gets a table entry by it's index number
    func getEntry(at index: Int, dynamicTable: Bool = true) throws -> HeadersTable.Entry {
        // First the static entries
        if index >= 0, index <= HeadersTable.staticEntries.count {
            // Tables start at 1
            return HeadersTable.staticEntries[index &- 1]
        }
        
        if !dynamicTable {
            throw HTTP2Error(.invalidTableIndex(index))
        }
        
        // Get the dynamic entry index
        let index = index &- HeadersTable.staticEntries.count &- 1
        
        // The dynamic entry *must* exist
        guard index < dynamicEntries.count else {
            throw HTTP2Error(.invalidTableIndex(index))
        }
        
        let entry = dynamicEntries[index]
        
        return entry
    }
    
    /// Removes any entiries that fall outside of the maximum table size
    func cleanTable() {
        // Remove extra entries if the table shrinks
        while currentTableSize > self.tableSize {
            let nextEntry = dynamicEntries.removeLast()
            currentTableSize -= nextEntry.octets
        }
    }
    
    /// Concatenation of static and dynamic entries
    ///
    /// http://httpwg.org/specs/rfc7541.html#rfc.section.2.3.3
    var dynamicEntries = [Entry]()
    
    static let authority = Entry(index: 1, name: ":authority")
    static let get = Entry(index: 2, name: ":method", value: "GET")
    static let post = Entry(index: 3, name: ":method", value: "POST")
    static let root = Entry(index: 4, name: ":path", value: "/")
    static let index = Entry(index: 5, name: ":path", value: "/index.html")
    static let http = Entry(index: 6, name: ":scheme", value: "http")
    static let https = Entry(index: 7, name: ":scheme", value: "https")
    
    static let ok = Entry(index: 8, name: ":status", value: "200")
    static let noContent = Entry(index: 9, name: ":status", value: "204")
    static let partialContent = Entry(index: 10, name: ":status", value: "206")
    static let notModified = Entry(index: 11, name: ":status", value: "304")
    static let badRequest = Entry(index: 12, name: ":status", value: "400")
    static let notFound = Entry(index: 13, name: ":status", value: "404")
    static let internalServerError = Entry(index: 14, name: ":status", value: "500")
    
    static let acceptCharset = Entry(index: 15, name: "accept-charset")
    static let acceptEncoding = Entry(index: 16, name: "accept-encoding", value: "gzip, deflate")
    static let acceptLanguages = Entry(index: 17, name: "accept-languages")
    static let acceptRanges = Entry(index: 18, name: "accept-ranges")
    static let accept = Entry(index: 19, name: "accept")
    static let accessControlAllowOrigin = Entry(index: 20, name: "access-control-allow-origin")
    static let age = Entry(index: 21, name: "age")
    static let allow = Entry(index: 22, name: "allow")
    static let authorization = Entry(index: 23, name: "authorization")
    static let cacheControl = Entry(index: 24, name: "cache-control")
    static let contentDisposition = Entry(index: 25, name: "content-disposition")
    static let contentEncoding = Entry(index: 26, name: "content-encoding")
    static let contentLanguage = Entry(index: 27, name: "content-language")
    static let contentLength = Entry(index: 28, name: "content-length")
    static let contentLocation = Entry(index: 29, name: "content-location")
    static let contentRange = Entry(index: 30, name: "content-range")
    static let contentType = Entry(index: 31, name: "content-type")
    static let cookie = Entry(index: 32, name: "cookie")
    static let date = Entry(index: 33, name: "date")
    static let etag = Entry(index: 34, name: "etag")
    static let expect = Entry(index: 35, name: "expect")
    static let expires = Entry(index: 36, name: "expires")
    static let from = Entry(index: 37, name: "from")
    static let host = Entry(index: 38, name: "host")
    static let ifMatch = Entry(index: 39, name: "if-match")
    static let ifModifiedSince = Entry(index: 40, name: "if-modified-since")
    static let ifNoneMatch = Entry(index: 41, name: "if-none-match")
    static let ifRange = Entry(index: 42, name: "if-range")
    static let ifUnmodifiedSince = Entry(index: 43, name: "if-unmodified-since")
    static let lastModified = Entry(index: 44, name: "last-modified")
    static let link = Entry(index: 45, name: "link")
    static let location = Entry(index: 46, name: "location")
    static let maxForwards = Entry(index: 47, name: "max-forwards")
    static let proxyAuthenticate = Entry(index: 48, name: "proxy-authenticate")
    static let proxyAuthorization = Entry(index: 49, name: "proxy-authorization")
    static let range = Entry(index: 50, name: "range")
    static let referer = Entry(index: 51, name: "referer")
    static let refresh = Entry(index: 52, name: "refresh")
    static let retryAfter = Entry(index: 53, name: "retry-after")
    static let server = Entry(index: 54, name: "server")
    static let setCookie = Entry(index: 55, name: "set-cookie")
    static let strictTransportSecurity = Entry(index: 56, name: "strict-transport-security")
    static let transferEncoding = Entry(index: 57, name: "transfer-encoding")
    static let userAgent = Entry(index: 58, name: "user-agent")
    static let vary = Entry(index: 59, name: "vary")
    static let via = Entry(index: 60, name: "via")
    static let wwwAuthenticate = Entry(index: 61, name: "www-authenticate")
    
    static let staticEntries = [
        authority, get, post, root, index, http, https,
        ok, noContent, partialContent, notModified, badRequest, notFound, internalServerError,
        acceptCharset, acceptEncoding, acceptLanguages, acceptRanges, accept,
        accessControlAllowOrigin, age, allow, authorization, cacheControl,
        contentDisposition, contentEncoding, contentLanguage, contentLength,
        contentLocation, contentRange, contentType, cookie, date, etag, expect, expires,
        from, host, ifMatch, ifModifiedSince, ifNoneMatch, ifRange, ifUnmodifiedSince,
        lastModified, link, location, maxForwards, proxyAuthenticate, proxyAuthorization,
        range, referer, refresh, retryAfter, server, setCookie, strictTransportSecurity,
        transferEncoding, userAgent, vary, via, wwwAuthenticate
    ]
    
    init() {}
}
