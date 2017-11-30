import Async
import Crypto
import Dispatch
import Foundation
import TCP
import HTTP
import TLS

extension WebSocket {
    /// Create a new WebSocket client in a future.
    ///
    /// The future will be completed with the WebSocket connection once the handshake using HTTP is complete.
    ///
    /// - parameter uri: The URI containing the remote host to connect to.
    /// - parameter worker: The Worker which this websocket will use for managing read and write operations
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/websocket/client/#connecting-a-websocket-client)
    public static func connect(
        to uri: URI,
        worker: Worker
    ) throws -> Future<WebSocket> {
        guard
            uri.scheme == "ws" || uri.scheme == "wss",
            let hostname = uri.hostname,
            let port = uri.port ?? uri.defaultPort
        else {
            throw WebSocketError(.invalidURI)
        }
        
        // A promise that will be completed with a websocket if it doesn't fail
        let promise = Promise<WebSocket>()
        
        // Creates an HTTP client for the handshake
        let serializer = RequestSerializer()
        
        let parser: ResponseParser
        
        // Generates the UUID that will make up the WebSocket-Key
        let id = OSRandom().data(count: 16).base64EncodedString()
        
        // Create a basic HTTP Request, requesting an upgrade
        let request = Request(method: .get, uri: uri, headers: [
            "Host": uri.hostname ?? "",
            "Connection": "Upgrade",
            "Sec-WebSocket-Key": id,
            "Sec-WebSocket-Version": "13"
        ], worker: worker)
        
        if uri.scheme == "wss" {
            let client = try TLSClient(on: worker)
            
            parser = client.stream(to: ResponseParser(maxSize: 50_000))
            
            try client.connect(hostname: hostname, port: port).do { _ in 
                // Send the initial request
                serializer.stream(to: client)
            }.catch(promise.fail)
            
            WebSocket.complete(to: promise, with: parser, id: id) {
                return WebSocket(socket: client, serverSide: false)
            }
        } else {
            // Create a new socket to the host
            var socket = try TCPSocket()
            try socket.connect(hostname: hostname, port: port)
            
            // The TCP Client that will be used by both HTTP and the WebSocket for communication
            let client = TCPClient(socket: socket, worker: worker)
            
            parser = client.stream(to: ResponseParser(maxSize: 50_000))
            
            client.writable().do {
                // Start reading in the client
                client.start()
                
                // Send the initial request
                serializer.stream(to: client)
            }.catch(promise.fail)
            
            WebSocket.complete(to: promise, with: parser, id: id) {
                return WebSocket(socket: client, serverSide: false)
            }
        }
        
        serializer.onInput(request)
        
        return promise.future
    }
    
    fileprivate static func complete(to promise: Promise<WebSocket>, with parser: ResponseParser, id: String, factory: @escaping (() -> WebSocket)) {
        // Calculates the expected key
        let expectatedKey = Base64Encoder.encode(data: SHA1.hash(id + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
        
        let expectedKeyString = String(bytes: expectatedKey, encoding: .utf8) ?? ""
        
        // Sets up the handler for the handshake
        parser.drain { response in
            // The server must accept the upgrade
            guard
                response.status == .upgrade,
                response.headers[.connection] == "Upgrade",
                response.headers[.upgrade] == "websocket"
            else {
                promise.fail(WebSocketError(.notUpgraded))
                return
            }
            
            // Protocol version 13 uses `-Key` instead of `Accept`
            if response.headers[.secWebSocketAccept] == "13",
                response.headers[.secWebSocketKey] == expectedKeyString {
                promise.complete(factory())
            } else {
                // Fail if the handshake didn't return the expected accept-key
                guard response.headers["Sec-WebSocket-Accept"] == expectedKeyString else {
                    promise.fail(WebSocketError(.notUpgraded))
                    return
                }
                
                // Complete using the new websocket
                promise.complete(factory())
            }
        }.catch { error in
            promise.fail(error)
        }
    }
}
