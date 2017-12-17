import JunkDrawer
import FluentSQLite
import Foundation
import Vapor

final class Pet: Model {
    static let keyStringMap: KeyStringMap = [
        key(\.id): "id",
        key(\.name): "name",
        key(\.ownerID): "ownerID"
    ]

    static let database = beta
    static let idKey = \Pet.id

    var id: UUID?
    var name: String
    var ownerID: User.ID?

    init(id: UUID? = nil, name: String, ownerID: User.ID) {
        self.id = id
        self.name = name
        self.ownerID = ownerID
    }

    var owner: Parent<Pet, User> {
        return parent(\.ownerID)
    }

    var toys: Siblings<Pet, Toy, PetToyPivot> {
        return siblings()
    }
}

extension Pet: Parameter {}

extension Pet: Migration {
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return connection.create(self) { schema in
            try schema.field(for: \.id)
            try schema.field(for: \.name)
            try schema.field(for: \.ownerID, referencing: \User.id, onDelete: .setNull)
        }
    }
    
    static func revert(on connection: SQLiteConnection) -> Future<Void> {
        return connection.delete(self)
    }
    
}
