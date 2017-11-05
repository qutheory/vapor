#if (os(macOS) || os(iOS)) && !OPENSSL
    import AppleSSL
#else
    import OpenSSL
#endif

import Async
import Bits
import Core
import Dispatch
import TCP

/// A Client (used for connecting to servers) that uses the platform specific SSL library.
public final class TLSClient: Async.Stream, ClosableStream {
    /// See `OutputStream.Notification`
    public typealias Notification = ByteBuffer
    
    /// See `InputStream.Input`
    public typealias Input = ByteBuffer
    
    /// See `OutputStream.outputStream`
    public var outputStream: NotificationCallback? {
        get {
            return ssl.outputStream
        }
        set {
            ssl.outputStream = newValue
        }
    }
    
    /// See `ClosableStream.closeNotification`
    public var closeNotification: SingleNotification<Void> {
        return ssl.closeNotification
    }
    
    /// See `Stream.errorStream`
    public var errorNotification: SingleNotification<Error> {
        return ssl.errorNotification
    }
    
    /// The AppleSSL (macOS/iOS) or OpenSSL (Linux) stream
    let ssl: SSLStream<TCPClient>
    
    /// The TCP that is used in the SSL Stream
    let client: TCPClient
    
    /// A DispatchQueue on which this Client executes all operations
    let queue: DispatchQueue
    
    /// The certificate used by the client, if any
    public var clientCertificatePath: String? = nil
    
    /// Creates a new `TLSClient` by specifying a queue.
    ///
    /// Can throw an error if the initialization phase fails
    public init(worker: Worker) throws {
        let socket = try Socket()
        
        self.queue = worker.queue
        self.client = TCPClient(socket: socket, worker: worker)
        self.ssl = try SSLStream(socket: self.client, descriptor: socket.descriptor, queue: queue)
    }
    
    /// Attempts to connect to a server on the provided hostname and port
    public func connect(hostname: String, port: UInt16) throws -> Future<Void> {
        try client.socket.connect(hostname: hostname, port: port)
        
        // Continues setting up SSL after the socket becomes writable (successful connection)
        return client.socket.writable(queue: queue).flatMap {
            return try self.ssl.initializeClient(hostname: hostname, signedBy: self.clientCertificatePath)
        }.map {
            self.ssl.start()
        }
    }
    
    /// Used for sending data over TLS
    public func inputStream(_ input: ByteBuffer) {
        ssl.inputStream(input)
    }
    
    public func close() {
        ssl.close()
    }
}
