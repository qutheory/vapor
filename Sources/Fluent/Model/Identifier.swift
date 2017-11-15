import Foundation

/// Types conforming to this protocol may be used
/// as identifiers for Fluent models.
public protocol ID: Codable, Equatable {
    /// The specific type of fluent identifier.
    /// This dictates how the identifier will behave when saved.
    static var identifierType: IDType<Self> { get }
}

/// MARK: Default supported types.

extension Int: ID {
    /// See Identifier.identifierType
    public static var identifierType: IDType<Int> {
        return .autoincrementing
    }
}

extension UUID: ID {
    /// See Identifier.identifierType
    public static var identifierType: IDType<UUID> {
        return .generated { UUID() }
    }
}

extension String: ID {
    /// See Identifier.identifierType
    public static var identifierType: IDType<String> {
        return .supplied
    }
}