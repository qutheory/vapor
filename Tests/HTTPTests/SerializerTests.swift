import Async
@testable import HTTP
import XCTest

class SerializerTests : XCTestCase {
    func testRequest() throws {
        let request = try Request(
            method: .post,
            uri: URI(path: "/foo"),
            body: "<vapor>",
            worker: EventLoop.default
        )
        
        let serializer = RequestSerializer()
        
        let expected = """
        POST /foo HTTP/1.1\r
        Content-Length: 7\r
        \r
        <vapor>
        """
        
        var ran = false
        
        serializer.drain { buffer in
            XCTAssertEqual(Data(buffer), expected.data(using: .utf8))
            ran = true
        }.catch { _ in
            XCTFail()
        }

        serializer.onInput(request)
        
        XCTAssert(ran)
    }
    
    func testChunkEncoder() {
        let encoder = ChunkEncoder()
        var buffer = [UInt8]("4\r\nWiki\r\n5\r\npedia\r\nE\r\n in\r\n\r\nchunks.\r\n0\r\n\r\n".utf8)
        
        var offset = 0
        
        encoder.drain { input in
            XCTAssertEqual(Array(input), Array(buffer[offset..<offset + input.count]))
            offset += input.count
        }.catch { _ in
            fatalError()
        }.finally {
            XCTAssertEqual(offset, buffer.count)
        }
        
        func send(_ string: String) {
            [UInt8](string.utf8).withUnsafeBufferPointer(encoder.onInput)
        }
        
        send("Wiki")
        send("pedia")
        send(" in\r\n\r\nchunks.")
        encoder.close()
    }
    
    static let allTests = [
        ("testRequest", testRequest)
    ]
}
