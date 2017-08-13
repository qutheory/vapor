import Cache
import Core
import Session
import XCTest

class SessionsProtocolTests: XCTestCase {
    static let allTests = [
        ("testMemory", testMemory),
        ("testCache", testCache),
        ("testCacheObject", testCacheObject),
    ]

    func testMemory() throws {
        let s = MemorySessions()
        let id = try s.makeIdentifier()

        XCTAssertNil(s.get(identifier: id))

        let session = Session(identifier: id, data: .string("bar"))
        s.set(session)
        XCTAssertEqual(s.get(identifier: id)?.data.string, "bar")

        try s.destroy(identifier: id)
        XCTAssertNil(s.get(identifier: id))
    }

    func testCache() throws {
        let m = MemoryCache()
        let s = CacheSessions(cache: m)
        let id = try s.makeIdentifier()

        XCTAssertNil(try s.get(identifier: id))

        let session = Session(identifier: id, data: .string("bar"))
        try s.set(session)
        XCTAssertEqual(try s.get(identifier: id)?.data.string, "bar")

        try s.destroy(identifier: id)
        XCTAssertNil(try s.get(identifier: id))
    }
    
    func testCacheObject() throws {
        let memory = MemoryCache()
        let sessions = CacheSessions(cache: memory)
        let id = try sessions.makeIdentifier()
        
        XCTAssert(try sessions.contains(identifier: id) == false)

        let session = Session(identifier: id)
        session.data = .dictionary(["foo": "bar"])
        try sessions.set(session)

        let fetched = try sessions.get(identifier: id)
        XCTAssertEqual(fetched?.data.dictionary?["foo"]?.string, "bar")

        try sessions.destroy(identifier: id)
        XCTAssert(try sessions.get(identifier: id) == nil)
    }
}
