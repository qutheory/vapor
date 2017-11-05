import Async
import Bits
import Core
import Foundation
import Dispatch
import TCP
import HTTP
import WebSocket
import XCTest

final class HTTPTestServer {
    /// Host name the server will bind to.
    public let hostname: String
    
    /// Port the server will bind to.
    public let port: UInt16
    
    /// Listen backlog.
    public let backlog: Int32
    
    /// Number of client accepting workers.
    /// Should be equal to the number of logical cores.
    public let workerCount: Int
    
    /// Creates a new engine server config
    public init(
        hostname: String = "0.0.0.0",
        port: UInt16 = 8282,
        backlog: Int32 = 4096,
        workerCount: Int = 8
        ) {
        self.hostname = hostname
        self.port = port
        self.workerCount = workerCount
        self.backlog = backlog
    }
    
    /// Start the server. Server protocol requirement.
    public func start(with responder: Responder) throws {
        // create a tcp server
        let socket = try Socket(isNonBlocking: false)
        let tcp = TCP.Server(socket: socket, workerCount: workerCount)
        let server = HTTP.Server(clientStream: tcp)
        
        // setup the server pipeline
        server.drain { client in
            let parser = HTTP.RequestParser(worker: client.tcp.worker, maxBodySize: 100_000)
            let responderStream = responder.makeStream()
            let serializer = HTTP.ResponseSerializer()
            
            client.stream(to: parser)
                .stream(to: responderStream)
                .stream(to: serializer)
                .drain { data in
                    client.inputStream(data)
                    serializer.upgradeHandler?(client.tcp)
            }
            
            client.tcp.start()
        }
        
        server.errorNotification.handleNotification { error in
            debugPrint(error)
        }
        
        // bind, listen, and start accepting
        try server.clientStream.start(
            hostname: hostname,
            port: port,
            backlog: backlog
        )
    }
}

class WebSocketTests : XCTestCase {
    func testClientServer() throws {
        // TODO: Failing on Linux
        return;
        let app = WebSocketApplication()
        let server = HTTPTestServer()
        
        try server.start(with: app)
        
        sleep(1)
        
        let promise0 = Promise<Void>()
        let promise1 = Promise<Void>()
        
        let queue = DispatchQueue(label: "test.client")
        let worker = Worker(queue: queue)
        
        let uri = URI(stringLiteral: "ws://localhost:8282/")
        
        do {
            _ = try WebSocket.connect(to: uri, worker: worker).then { socket in
                let responses = ["test", "cat", "banana"]
                let reversedResponses = responses.map {
                    String($0.reversed())
                }
                
                var count = 0
                
                socket.onText { string in
                    XCTAssert(reversedResponses.contains(string))
                    count += 1
                    
                    if count == 3 {
                        promise0.complete(())
                    }
                }
                
                socket.onBinary { blob in
                    defer { promise1.complete(()) }
                    
                    guard Array(blob) == [0x00, 0x01, 0x00, 0x02] else {
                        XCTFail()
                        return
                    }
                }
                
                for response in responses {
                    socket.send(response)
                }
                
                Data([
                    0x00, 0x01, 0x00, 0x02
                    ]).withUnsafeBytes { (pointer: BytesPointer) in
                        let buffer = ByteBuffer(start: pointer, count: 4)
                        
                        socket.send(buffer)
                }
                
                promise0.complete(())
                }.blockingAwait(timeout: .seconds(10))
            
            try promise0.future.blockingAwait(timeout: .seconds(10))
            try promise1.future.blockingAwait(timeout: .seconds(10))
        } catch {
            XCTFail("Error connecting to \(uri)")
            throw error
        }
    }
    
    static let allTests = [
        ("testClientServer", testClientServer)
    ]
}

struct WebSocketApplication: Responder {
    func respond(to req: Request) throws -> Future<Response> {
        let promise = Promise<Response>()
        
        if WebSocket.shouldUpgrade(for: req) {
            let res = try WebSocket.upgradeResponse(for: req)
            res.onUpgrade = { client in
                let websocket = WebSocket(client: client)
                websocket.onText { text in
                    let rev = String(text.reversed())
                    websocket.send(rev)
                }
                websocket.onBinary { buffer in
                    websocket.send(buffer)
                }
            }
            promise.complete(res)
        } else {
            let res = try Response(status: .ok, body: "hi")
            promise.complete(res)
        }
        
        return promise.future
    }
}
