import HTTP

/// Option for the allow origin header in responses for CORS requests.
///
/// - none: Disallows any origin.
/// - originBased: Uses value of the origin header in the request.
/// - all: Uses wildcard to allow any origin.
/// - custom: Uses custom string provided as an associated value.
public enum AllowOriginSetting {

    /// Disallow any origin.
    case none

    /// Uses value of the origin header in the request.
    case originBased

    /// Uses wildcard to allow any origin.
    case all

    /// Uses custom string provided as an associated value.
    case custom(String)


    /// Creates the header string depending on the case of self.
    ///
    /// - Parameter request: Request for which the allow origin header should be created.
    /// - Returns: Header string to be used in response for allowed origin.
    public func header(forRequest request: Request) -> String {
        switch self {
        case .none: return ""
        case .originBased: return request.headers["Origin"] ?? ""
        case .all: return "*"
        case .custom(let string): return string
        }
    }
}

/// Configuration used for populating headers in response for CORS requests.
public struct CORSConfiguration {

    /// Default CORS configuration.
    ///
    /// - Allow Origin: Based on request's `Origin` value.
    /// - Allow Methods: `GET`, `POST`, `PUT`, `OPTIONS`, `DELETE`, `PATCH`
    /// - Allow Headers: `Accept`, `Authorization`, `Content-Type`, `Origin`, `X-Requested-With`
    public static let `default` = CORSConfiguration(
        allowedOrigin: .originBased,
        allowedMethods: [.get, .post, .put, .options, .delete, .patch],
        allowedHeaders: ["Accept", "Authorization", "Content-Type", "Origin", "X-Requested-With"]
    )


    /// Setting that controls which origin values are allowed.
    public let allowedOrigin: AllowOriginSetting

    /// Header string containing methods that are allowed for a CORS request response.
    public let allowedMethods: String

    /// Header string containing headers that are allowed in a response for CORS request.
    public let allowedHeaders: String

    /// If set to yes, cookies and other credentials will be sent in the response for CORS request.
    public let allowCredentials: Bool

    /// Optionally sets expiration of the cached pre-flight request. Value is in seconds.
    public let cacheExpiration: Int?

    /// Headers exposed in the response fo pre-flight request.
    public let exposedHeaders: String?

    public init(allowedOrigin: AllowOriginSetting,
                allowedMethods: [Method],
                allowedHeaders: [String],
                allowCredentials: Bool = false,
                cacheExpiration: Int? = 600,
                exposedHeaders: [String]? = nil) {
        self.allowedOrigin = allowedOrigin
        self.allowedMethods = allowedMethods.map({ $0.description }).joined(separator: ", ")
        self.allowedHeaders = allowedHeaders.joined(separator: ", ")
        self.allowCredentials = allowCredentials
        self.cacheExpiration = cacheExpiration
        self.exposedHeaders = exposedHeaders?.joined(separator: ", ")
    }
}

extension CORSConfiguration: ConfigInitializable {
    public init(config: Settings.Config) throws {
        let cors: Node = try config.extract("cors") ?? config.extract("CORS")

        // Allowed origin
        let originString = try cors.extract("allowedOrigin").string
        switch originString {
        case "all", "*": self.allowedOrigin = .all
        case "none", "": self.allowedOrigin = .none
        case "origin", "Origin": self.allowedOrigin = .originBased
        default: self.allowedOrigin = .custom(originString)
        }

        // Get methods
        let methodArray: [String] = try cors.extract("allowedMethods")
        self.allowedMethods = methodArray.joined(separator: ", ")

        // Get allowed headers
        let headersArray: [String] = try cors.extract("allowedHeaders")
        self.allowedHeaders = headersArray.joined(separator: ", ")

        // Allow credentials
        let allowCredentials: Bool? = try cors.extract("allowCredentials")
        self.allowCredentials = allowCredentials ?? false

        // Cache expiration
        self.cacheExpiration = try cors.extract("cacheExpiration") ?? 600

        // Exposed headers
        self.exposedHeaders = try cors.extract("exposedHeaders")
    }
}
