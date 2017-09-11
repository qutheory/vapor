import Dispatch
import Foundation
import libc
import Bits
import Async

/// TCP client stream.
public final class Client: Async.Stream {
    // MARK: Stream
    public typealias Input = DispatchData
    public typealias Output = ByteBuffer
    public var errorStream: ErrorHandler?
    public var outputStream: OutputHandler?

    /// This client's dispatch queue. Use this
    /// for all async operations performed as a
    /// result of this client.
    public let queue: DispatchQueue

    /// The client stream's underlying socket.
    public let socket: Socket

    // Bytes from the socket are read into this buffer.
    // Views into this buffer supplied to output streams.
    let outputBuffer: MutableByteBuffer

    // Data being fed into the client stream is stored here.
    var inputBuffer: DispatchData?

    // Stores read event source.
    var readSource: DispatchSourceRead?

    // Stores write event source.
    var writeSource: DispatchSourceWrite?

    /// Creates a new Remote Client from the ServerSocket's details
    public init(socket: Socket, queue: DispatchQueue) {
        self.socket = socket
        self.queue = queue

        // Allocate one TCP packet
        let size = 65_507
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        self.outputBuffer = MutableByteBuffer(start: pointer, count: size)
    }

    // MARK: Stream

    /// Handles stream input
    public func inputStream(_ input: DispatchData) {
        if inputBuffer == nil {
            inputBuffer = input
            writeSource?.resume()
        } else {
            inputBuffer?.append(input)
        }

        if writeSource == nil {
            let source = DispatchSource.makeWriteSource(
                fileDescriptor: socket.descriptor.raw,
                queue: queue
            )
            
            source.setEventHandler {
                // important: make sure to suspend or else writeable
                // will keep calling.
                self.writeSource?.suspend()

                // grab input buffer
                guard let data = self.inputBuffer else {
                    return
                }
                self.inputBuffer = nil

                // copy input into contiguous data and write it.
                let copied = Data(data)
                let buffer = ByteBuffer(start: copied.withUnsafeBytes { $0 }, count: copied.count)
                do {
                    _ = try self.socket.write(max: copied.count, from: buffer)
                    // FIXME: we should verify the lengths match here.
                } catch {
                    // any errors that occur here cannot be thrown,
                    // so send them to stream error catcher.
                    self.errorStream?(error)
                }
            }

            source.setCancelHandler {
                self.close()
            }

            source.resume()
            writeSource = source
        }
    }

    /// Starts receiving data from the client
    public func start() {
        let source = DispatchSource.makeReadSource(
            fileDescriptor: socket.descriptor.raw,
            queue: queue
        )

        source.setEventHandler {
            let read: Int
            do {
                read = try self.socket.read(
                    max: self.outputBuffer.count,
                    into: self.outputBuffer
                )
            } catch {
                // any errors that occur here cannot be thrown,
                //selfso send them to stream error catcher.
                self.errorStream?(error)
                return
            }

            guard read > 0 else {
                // need to close!!! gah
                self.close()
                return
            }

            // create a view into our internal buffer and
            // send to the output stream
            let bufferView = ByteBuffer(
                start: self.outputBuffer.baseAddress,
                count: read
            )
            self.outputStream?(bufferView)
        }

        source.setCancelHandler {
            self.close()
        }

        source.resume()
        readSource = source
    }

    /// Closes the client.
    public func close() {
        // important!!!!!!
        // for some reason you can't cancel a suspended write source
        // if you remove this line, your life will be ruined forever!!!
        if self.inputBuffer == nil {
            writeSource?.resume()
        }
        readSource = nil
        writeSource = nil
        socket.close()
        // important! it's common for a client to drain into itself
        // we need to make sure to break that reference cycle
        outputStream = nil
        errorStream = nil
    }

    /// Deallocated the pointer buffer
    deinit {
        outputBuffer.baseAddress.unsafelyUnwrapped.deallocate(capacity: outputBuffer.count)
        outputBuffer.baseAddress.unsafelyUnwrapped.deinitialize()
    }
}
