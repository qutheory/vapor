import Bits
import CHTTP
import Async
import Dispatch
import Foundation

/// Parses requests from a readable stream.
public final class RequestParser: CParser {
    /// See InputStream.Input
    public typealias Input = ByteBuffer

    /// See OutputStream.Output
    public typealias Output = Request

    // Internal variables to conform
    // to the C HTTP parser protocol.
    var parser: http_parser
    var settings: http_parser_settings
    var state:  CHTTPParserState

    /// Queue to be set on messages created by this parser.
    private let worker: Worker

    /// The maxiumum possible body size
    /// larger sizes will result in an error
    private let maxSize: Int
    
    /// The currently parsing request's size
    private var currentSize = 0

    /// Use a basic stream to easily implement our output stream.
    private var outputStream: BasicStream<Output>

    /// Creates a new Request parser.
    public init(on worker: Worker, maxSize: Int) {
        self.parser = http_parser()
        self.settings = http_parser_settings()
        self.state = .ready
        self.worker = worker
        self.maxSize = maxSize
        self.outputStream = .init()
        reset(HTTP_REQUEST)
    }

    /// Handles incoming stream data
    /// See InputStream.onInput
    public func onInput(_ input: ByteBuffer) {
        do {
            guard let request = try parse(from: input) else {
                return
            }
            
            self.outputStream.onInput(request)
        } catch {
            self.onError(error)
            reset(HTTP_REQUEST)
        }
    }

    /// See InputStream.onError
    public func onError(_ error: Error) {
        outputStream.onError(error)
    }

    /// See OutputStream.onOutput
    public func onOutput<I>(_ input: I) where I: Async.InputStream, Output == I.Input {
        outputStream.onOutput(input)
    }
    
    /// See ClosableStream.close
    public func close() {
        self.outputStream.close()
    }
    
    /// See ClosableStream.onClose
    public func onClose(_ onClose: ClosableStream) {
        self.outputStream.onClose(onClose)
    }

    /// Parses request Data. If the data does not contain
    /// an entire HTTP request, nil will be returned and
    /// the parser will remain ready to accept new Data.
    public func parse(from data: Data) throws -> Request? {
        return try data.withUnsafeBytes { (pointer: BytesPointer) in
            let buffer = ByteBuffer(start: pointer, count: data.count)
            return try parse(from: buffer)
        }
    }

    /// Parses a Request from the stream.
    public func parse(from buffer: ByteBuffer) throws -> Request? {
        currentSize += buffer.count
        
        guard currentSize < maxSize else {
            throw HTTPError(identifier: "too-large-response", reason: "The response's size was not an acceptable size")
        }
        
        let results: CParseResults

        switch state {
        case .ready:
            // create a new results object and set
            // a reference to it on the parser
            let newResults = CParseResults.set(on: &parser, maxSize: maxSize)
            results = newResults
            state = .parsing
        case .parsing:
            // get the current parse results object
            guard let existingResults = CParseResults.get(from: &parser) else {
                return nil
            }
            results = existingResults
        }

        /// parse the message using the C HTTP parser.
        try executeParser(max: buffer.count, from: buffer)

        guard results.isComplete else {
            return nil
        }

        // the results have completed, so we are ready
        // for a new request to come in
        state = .ready
        CParseResults.remove(from: &parser)


        /// switch on the C method type from the parser
        let method: Method
        switch http_method(parser.method) {
        case HTTP_DELETE:
            method = .delete
        case HTTP_GET:
            method = .get
        case HTTP_POST:
            method = .post
        case HTTP_PUT:
            method = .put
        case HTTP_OPTIONS:
            method = .options
        case HTTP_PATCH:
            method = .patch
        default:
            /// custom method detected,
            /// convert the method into a string
            /// and use Engine's other type
            guard
                let pointer = http_method_str(http_method(parser.method)),
                let string = String(validatingUTF8: pointer)
            else {
                throw HTTPError.invalidMessage()
            }
            method = Method(string)
        }

        // parse the uri from the url bytes.
        var uri = URIParser.shared.parse(data: results.url)

        // if there is no scheme, use http by default
        if uri.scheme?.isEmpty == true {
            uri.scheme = "http"
        }

        // require a version to have been parsed
        guard let version = results.version else {
            throw HTTPError.invalidMessage()
        }

        let body = Body(results.body)
        
        let headers = Headers(storage: results.headersData, indexes: results.headersIndexes)
        
        currentSize = 0

        // create the request
        return Request(
            method: method,
            uri: uri,
            version: version,
            headers: headers,
            body: body,
            worker: worker
        )
    }
}

