import Async
import Dispatch
import COperatingSystem

/// Any TCP socket. It doesn't specify being a server or client yet.
public struct TCPSocket {
    /// The file descriptor related to this socket
    public let descriptor: Int32

    /// The remote's address
    public var address: Address?
    
    /// True if the socket is non blocking
    public let isNonBlocking: Bool

    /// True if the socket should re-use addresses
    public let shouldReuseAddress: Bool
    
    /// A read source that's used to check when the connection is readable
    internal var readSource: DispatchSourceRead?
    
    /// A write source that's used to check when the connection is open
    internal var writeSource: DispatchSourceWrite?

    /// Creates a TCP socket around an existing descriptor
    public init(
        established: Int32,
        isNonBlocking: Bool,
        shouldReuseAddress: Bool,
        address: Address?
    ) {
        self.descriptor = established
        self.isNonBlocking = isNonBlocking
        self.shouldReuseAddress = shouldReuseAddress
        self.address = address
    }
    
    /// Creates a new TCP socket
    public init(
        isNonBlocking: Bool = true,
        shouldReuseAddress: Bool = true
    ) throws {
        let sockfd = socket(AF_INET, SOCK_STREAM, 0)
        guard sockfd > 0 else {
            throw TCPError.posix(errno, identifier: "socketCreate")
        }
        
        if isNonBlocking {
            // Set the socket to async/non blocking I/O
            guard fcntl(sockfd, F_SETFL, O_NONBLOCK) == 0 else {
                throw TCPError.posix(errno, identifier: "setNonBlocking")
            }
        }

        if shouldReuseAddress {
            var yes = 1
            let intSize = socklen_t(MemoryLayout<Int>.size)
            guard setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &yes, intSize) == 0 else {
                throw TCPError.posix(errno, identifier: "setReuseAddress")
            }
        }

        self.init(
            established: sockfd,
            isNonBlocking: isNonBlocking,
            shouldReuseAddress: shouldReuseAddress,
            address: nil
        )
    }
    
    public func disablePipeSignal() {
        signal(SIGPIPE, SIG_IGN)
        
        #if !os(Linux)
            var n = 1
            setsockopt(self.descriptor, SOL_SOCKET, SO_NOSIGPIPE, &n, numericCast(MemoryLayout<Int>.size))
        #endif
        
//         TODO: setsockopt(self.descriptor, SOL_TCP, TCP_NODELAY, &n, numericCast(MemoryLayout<Int>.size)) ?
    }

    /// Closes the socket
    public func close() {
        COperatingSystem.close(descriptor)
    }
    
    /// Returns a boolean describing if the socket is still healthy and open
    public var isConnected: Bool {
        var error = 0
        getsockopt(descriptor, SOL_SOCKET, SO_ERROR, &error, nil)
        
        return error == 0
    }
}
