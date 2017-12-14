import Async
import JunkDrawer
import Fluent
import Foundation

final class KitchenSink<D: Database>: Model {
    /// See Model.ID
    typealias ID = String

    /// See Model.keyStringMap
    static var keyStringMap: KeyStringMap {
        return [key(\.id): "id"]
    }

    /// See Model.idKey
    static var idKey: IDKey { return \.id }

    /// See Model.database
    static var database: DatabaseIdentifier<D> { return .init("kitchenSink") }

    /// KitchenSink's identifier
    var id: String?
}

internal struct KitchenSinkSchema<
    D: Database
>: Migration where D.Connection: SchemaSupporting {
    /// See Migration.Database
    typealias Database = D

    /// See Migration.prepare
    static func prepare(on connection: D.Connection) -> Signal {
        return connection.create(KitchenSink<Database>.self) { builder in
            try builder.addField(
                type: Database.Connection.FieldType.requireSchemaFieldType(for: UUID.self),
                name: "id"
            )
            try builder.addField(
                type: Database.Connection.FieldType.requireSchemaFieldType(for: String.self),
                name: "string"
            )
            try builder.addField(
                type: Database.Connection.FieldType.requireSchemaFieldType(for: Int.self),
                name: "int"
            )
            try builder.addField(
                type: Database.Connection.FieldType.requireSchemaFieldType(for: Double.self),
                name: "double"
            )
            try builder.addField(
                type: Database.Connection.FieldType.requireSchemaFieldType(for: Date.self),
                name: "date"
            )
        }
    }

    /// See Migration.revert
    static func revert(on connection: D.Connection) -> Signal {
        return connection.delete(KitchenSink<Database>.self)
    }
}
