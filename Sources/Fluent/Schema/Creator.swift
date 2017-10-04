/// A schema builder for creating schema
public final class Creator: Builder {
    /// Entity being built
    public var entity: Model.Type
    
    /// The fields to be created
    public var fields: [RawOr<Field>]
    
    /// The foreign keys to be created
    public var foreignKeys: [RawOr<ForeignKey>]
    
    /// Creates a new schema creator
    public init(_ e: Model.Type) {
        entity = e
        fields = []
        foreignKeys = []
    }
}
