import Foundation
import FormURLEncoded

/// Configures which encoders/decoders to use for a given media type.
public struct ContentConfig: Service, ServiceType {
    /// See `ServiceType.serviceSupports`
    public static let serviceSupports: [Any.Type] = []

    /// See `ServiceType.makeService`
    public static func makeService(for worker: Container) throws -> ContentConfig {
        return ContentConfig.default()
    }

    /// Represents a yet-to-be-configured object.
    typealias Lazy<T> = (Container) throws -> T

    /// Configured encoders.
    private var lazyEncoders: [MediaType: Lazy<BodyEncoder>]

    /// Configured decoders.
    private var lazyDecoders: [MediaType: Lazy<BodyDecoder>]

    /// Create a new content config.
    public init() {
        self.lazyEncoders = [:]
        self.lazyDecoders = [:]
    }

    /// Adds an encoder for the specified media type.
    public mutating func use(encoder: BodyEncoder, for mediaType: MediaType) {
        self.lazyEncoders[mediaType] = { container in
            return encoder
        }
    }

    /// Adds a decoder for the specified media type.
    public mutating func use(decoder: BodyDecoder, for mediaType: MediaType) {
        self.lazyDecoders[mediaType] = { container in
            return decoder
        }
    }

    /// Adds an encoder for the specified media type.
    public mutating func use<B>(encoder: B.Type, for mediaType: MediaType) where B: BodyEncoder {
        self.lazyEncoders[mediaType] = { container in
            return try container.make(B.self, for: ContentConfig.self)
        }
    }

    /// Adds a decoder for the specified media type.
    public mutating func use<B>(decoder: B.Type, for mediaType: MediaType) where B: BodyDecoder {
        self.lazyDecoders[mediaType] = { container in
            return try container.make(B.self, for: ContentConfig.self)
        }
    }

    /// Creates all lazy coders.
    internal func boot(using container: Container) throws -> ContentCoders {
        return try ContentCoders(
            encoders: lazyEncoders.mapValues { try $0(container) },
            decoders: lazyDecoders.mapValues { try $0(container) }
        )
    }
}

/// MARK: Coders

public struct ContentCoders: Service, ServiceType {
    /// See `ServiceType.serviceSupports`
    public static let serviceSupports: [Any.Type] = []

    /// See `ServiceType.makeService`
    public static func makeService(for worker: Container) throws -> ContentCoders {
        let config = try worker.make(ContentConfig.self, for: ContentCoders.self)
        return try config.boot(using: worker)
    }

    /// Configured encoders.
    var encoders: [MediaType: BodyEncoder]

    /// Configured decoders.
    var decoders: [MediaType: BodyDecoder]

    /// Returns an encoder for the specified media type or throws an error.
    public func requireEncoder(for mediaType: MediaType) throws -> BodyEncoder {
        guard let encoder = encoders[mediaType] else {
            throw VaporError(identifier: "contentEncoder", reason: "There is no configured encoder for \(mediaType)")
        }

        return encoder
    }

    /// Returns a decoder for the specified media type or throws an error.
    public func requireDecoder(for mediaType: MediaType) throws -> BodyDecoder {
        guard let decoder = decoders[mediaType] else {
            throw VaporError(identifier: "contentDecoder", reason: "There is no configured decoder for \(mediaType)")
        }

        return decoder
    }
}

/// MARK: Default

extension ContentConfig {
	private static func iso8601Formatter() -> DateFormatter {
		let formatter = DateFormatter()
		formatter.calendar = Calendar(identifier: .iso8601)
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
		return formatter
	}
	
    public static func `default`() -> ContentConfig {
        var config = ContentConfig()

        // json
		let encoder = JSONEncoder()
		let decoder = JSONDecoder()
		
		if #available(OSX 10.12, *) {
			encoder.dateEncodingStrategy = .iso8601
			decoder.dateDecodingStrategy = .iso8601
		} else {
			encoder.dateEncodingStrategy = .formatted(iso8601Formatter())
			decoder.dateDecodingStrategy = .formatted(iso8601Formatter())
		}
		
		config.use(encoder: encoder, for: .json)
		config.use(decoder: decoder, for: .json)

        // data
        config.use(encoder: DataEncoder(), for: .plainText)
        config.use(encoder: DataEncoder(), for: .html)

        // form-urlencoded
        config.use(encoder: FormURLEncoder(), for: .urlEncodedForm)
        config.use(decoder: FormURLDecoder(), for: .urlEncodedForm)

        return config
    }
}

extension FormURLEncoder: BodyEncoder {}
extension FormURLDecoder: BodyDecoder {}
