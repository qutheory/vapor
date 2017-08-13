import Crypto

/// Session storage engines that conform to this
/// protocol can be used to power the Session class.
public protocol Sessions {
    /// Creates a new, random identifier
    /// to use for storing a Session
    func makeIdentifier() throws -> String

    /// Loads a session for the given identifier--
    /// if one exists.
    func get(identifier: String) throws -> Session?

    /// Stores the session, using its identifier.
    func set(_ session: Session) throws

    /// Destroys the session associated with the identifier
    func destroy(identifier: String) throws

    /// Returns true if a session with this identifier exists
    func contains(identifier: String) throws -> Bool
}

extension Sessions {
    /// See Sessions.contains()
    public func contains(identifier: String) throws -> Bool {
        return try get(identifier: identifier) != nil
    }

    /// See Sessions.makeIdentifier()
    public func makeIdentifier() throws -> String {
        return try Self.randomBase64String(byteCount: 16)
    }
}

// MARK: Utilities

extension Sessions {
    /// Generates a random Base64 encoded string.
    public static func randomBase64String(byteCount: Int) throws -> String {
        return try Crypto.Random.bytes(count: byteCount).base64Encoded.makeString()
    }
}
