/// A basic stream implementation that maps input
/// through a closure.
///
/// Example using a number emitter and map stream to square numbers:
///
///     let numberEmitter = EmitterStream(Int.self)
///     let squareMapStream = MapStream<Int, Int> { int in
///         return int * int
///     }
///
///     var squares: [Int] = []
///
///     numberEmitter.stream(to: squareMapStream).drain { square in
///         squares.append(square)
///     }
///
///     numberEmitter.emit(1)
///     numberEmitter.emit(2)
///     numberEmitter.emit(3)
///
///     print(squares) // [1, 4, 9]
///
public final class MapStream<In, Out>: Stream {
    /// See InputStream.Input
    public typealias Input = In

    /// See OutputStream.Output
    public typealias Output = Out

    /// See OutputStream.outputStream
    public var outputStream: OutputHandler?

    /// See BaseStream.errorStream
    public var errorStream: ErrorHandler?

    /// Maps input to output
    public typealias MapClosure = (In) throws -> (Out)

    /// The stored map closure
    public let transform: MapClosure

    /// Create a new Map stream with the supplied closure.
    public init(transform: @escaping MapClosure) {
        self.transform = transform
    }

    /// See InputStream.inputStream
    public func inputStream(_ input: In) {
        do {
            let output = try transform(input)
            outputStream?(output)
        } catch {
            errorStream?(error)
        }
    }
}

extension OutputStream {
    public func map<T>(_ transform: @escaping ((Output) throws -> (T))) -> MapStream<Output, T> {
        let stream = MapStream(transform: transform)
        self.drain(into: stream)
        
        return stream
    }
}
