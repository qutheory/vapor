import Async
import Bits
import Dispatch
import Foundation
import TCP

/// A Redis client
///
/// Wraps around the provided Connection/Closable Binary Stream
public final class RedisClient<DuplexByteStream: Async.Stream> where DuplexByteStream.Input == ByteBuffer, DuplexByteStream.Notification == ByteBuffer, DuplexByteStream: ClosableStream {
    /// The closable binary stream that this client runs on
    let socket: DuplexByteStream
    
    /// Parses redis data from binary
    let dataParser = DataParser()
    
    /// Serializes redis data to binary
    let dataSerializer = DataSerializer()
    
    /// Keeps track of whether this client is currently subscribed to a channel
    var isSubscribed = false
    
    /// The maximum size of a single response. Prevents excessive memory usage
    public var maximumResponseSize: Int {
        get {
            return dataParser.maximumResponseSize
        }
        set {
            dataParser.maximumResponseSize = newValue
        }
    }
    
    /// Runs a Value as a command
    ///
    /// - returns: A future containing the server's response
    /// - throws: On network error
    public func run(command: String, arguments: [RedisData]? = nil) -> Future<RedisData> {
        if isSubscribed {
            return Future(error: RedisError(.cannotReuseSubscribedClients))
        }
        
        let promise = Promise<RedisData>()
        
        dataParser.responseQueue.append(promise)
        
        let arguments = arguments ?? []
        let command = RedisData.array([.bulkString(command)] + arguments)
        
        dataSerializer.inputStream(command)
        
        return promise.future
    }
    
    /// Creates a pipeline and returns it.
    func makePipeline() -> Pipeline {
        return Pipeline(self)
    }
    
    /// Creates a new Redis client on the provided connection
    public init(socket: DuplexByteStream) {
        self.socket = socket
        
        socket.errorNotification.handleNotification { _ in
            socket.close()
        }
        
        dataSerializer.drain(into: socket)
        socket.drain(into: dataParser)
    }
}

extension RedisClient where DuplexByteStream == TCPClient {
    /// Connects to `Redis` using on a TCP socket to the provided hostname and port
    ///
    /// Listens to the socket using the provided `DispatchQueue`
    public static func connect(hostname: String = "localhost", port: UInt16 = 6379, worker: Worker) throws -> Future<RedisClient<TCPClient>> {
        let socket = try TCP.Socket()
        try socket.connect(hostname: hostname, port: port)
        
        return socket.writable(queue: worker.queue).map { _ in
            let client = TCPClient(socket: socket, worker: worker)
            client.start()
            
            return RedisClient<TCPClient>(socket: client)
        }
    }
}
