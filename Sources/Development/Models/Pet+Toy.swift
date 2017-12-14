import Async
import JunkDrawer
import Fluent
import Foundation
import SQLite
import FluentSQLite

final class PetToyPivot: ModifiablePivot {
    typealias Left = Pet
    typealias Right = Toy

    static let idKey = \PetToyPivot.id
    static let leftIDKey = \PetToyPivot.petID
    static var rightIDKey = \PetToyPivot.toyID
    static let database = beta

    static let keyStringMap: KeyStringMap = [
        key(\.id): "id",
        key(\.petID): "petID",
        key(\.toyID): "toyID"
    ]

    var id: UUID?
    var petID: UUID
    var toyID: UUID

    init(_ pet: Pet, _ toy: Toy) throws {
        petID = try pet.requireID()
        toyID = try toy.requireID()
    }
}

extension PetToyPivot: Migration {
    static func prepare(on connection: SQLiteConnection) -> Signal {
        return connection.create(self) { schema in
            try schema.field(for: \.id)
            try schema.field(for: \.petID)
            try schema.field(for: \.toyID)
        }
    }

    static func revert(on connection: SQLiteConnection) -> Signal {
        return connection.delete(self)
    }
}
