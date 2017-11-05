import Async
import Bits
import Foundation

/// A streaming Redis value serializer
final class DataSerializer: Async.Stream {
    /// See `InputStream.Input`
    typealias Input = RedisData
    
    /// See `OutputStream.Notification`
    typealias Notification = ByteBuffer
    
    /// See `BaseStream.errorNotification`
    let errorNotification = SingleNotification<Error>()
    
    /// See `OutputStream.outputStream`
    var outputStream: NotificationCallback?

    /// Creates a new ValueSerializer
    init() {}
    
    /// Serializes a value to the outputStream
    func inputStream(_ input: RedisData) {
        let message = input.serialize()
            
        message.withUnsafeBytes { (pointer: BytesPointer) in
            let buffer = ByteBuffer(start: pointer, count: message.count)
            outputStream?(buffer)
        }
    }
}

extension DataSerializer {
    
    /// Used for pipelining commands
    /// Concatenates commands to RedisData for the outputStream
    func inputStream(_ input: [RedisData]) {
        var buffer = Data()
        for item in input {
            buffer.append(contentsOf: item.serialize())
        }
        buffer.withUnsafeBytes { (pointer: BytesPointer) in
            let buffer = ByteBuffer(start: pointer, count: buffer.count)
            outputStream?(buffer)
        }
    }
    
}

/// Static "fast" route for serializing `null` values
fileprivate let nullData = Data("$-1\r\n".utf8)

extension RedisData {
    /// Serializes a single value
    func serialize() -> Data {
        switch self.storage {
        case .null:
            return nullData
        case .basicString(let string):
            return Data(("+" + string).utf8)
        case .error(let error):
            return Data(("-" + error.reason).utf8)
        case .integer(let int):
            return Data(":\(int)\r\n".utf8)
        case .bulkString(let data):
            return Data("$\(data.count)\r\n".utf8) + data + Data("\r\n".utf8)
        case .array(let values):
            var buffer = Data("*\(values.count)\r\n".utf8)
            for value in values {
                buffer.append(contentsOf: value.serialize())
            }
            buffer.append(contentsOf: Data("\r\n".utf8))
            return buffer
        }
    }
}
