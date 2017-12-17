import Foundation
import Async
import Bits

/// Any MySQL packet
internal final class Packet: ExpressibleByArrayLiteral {
    /// Keeps track of the mutability of the buffer so it can be deallocated
    enum Buffer {
        case mutable(MutableByteBuffer)
        case immutable(ByteBuffer)
    }
    
    // Maximum payload size
    static let maxPayloadSize: Int = 16_777_216
    
    /// The sequence ID is incremented per message
    /// This client doesn't use this
    var sequenceId: UInt8 {
        return buffer[3]
    }
    
    /// The payload contains the packet's data
    var payload: ByteBuffer {
        let buffer = self.buffer
        
        return ByteBuffer(start: buffer.baseAddress?.advanced(by: 4), count: buffer.count &- 4)
    }
    
    /// The payload contains the packet's data
    var buffer: ByteBuffer {
        switch _buffer {
        case .immutable(let buffer):
            // UInt24 + sequenceId
            return buffer
        case .mutable(let buffer):
            // UInt24 + sequenceId
            return ByteBuffer(start: buffer.baseAddress, count: buffer.count)
        }
    }
    
    var _buffer: Buffer
    
    /// Creates a new packet
    init(payload: ByteBuffer) {
        self._buffer = .immutable(payload)
    }
    
    /// Creates a new packet
    init(payload: MutableByteBuffer) {
        self._buffer = .mutable(payload)
    }
    
    deinit {
        if case .mutable(let buffer) = _buffer {
            // Deallocates the MySQL buffer
            buffer.baseAddress?.deallocate(capacity: buffer.count)
        }
    }
    
    convenience init(arrayLiteral elements: UInt8...) {
        let pointer = MutableBytesPointer.allocate(capacity: 4 &+ elements.count)
        
        let packetSizeBytes = [
            UInt8((elements.count) & 0xff),
            UInt8((elements.count >> 8) & 0xff),
            UInt8((elements.count >> 16) & 0xff),
        ]

        memcpy(pointer, packetSizeBytes, 3)
        memcpy(pointer.advanced(by: 4), elements, elements.count)
        
        self.init(payload: ByteBuffer(start: pointer, count: 4 &+ elements.count))
    }
    
    convenience init(data: Data) {
        let pointer = MutableBytesPointer.allocate(capacity: 4 &+ data.count)
        
        let packetSizeBytes = [
            UInt8((data.count) & 0xff),
            UInt8((data.count >> 8) & 0xff),
            UInt8((data.count >> 16) & 0xff),
        ]
        
        memcpy(pointer, packetSizeBytes, 3)
        
        data.withByteBuffer { buffer in
            _ = memcpy(pointer.advanced(by: 4), buffer.baseAddress!, data.count)
        }
        
        self.init(payload: ByteBuffer(start: pointer, count: 4 &+ data.count))
    }
}
