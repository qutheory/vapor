import Debugging
import Foundation
import libc

/// Errors that can be thrown while working with Vapor.
public struct VaporError: Traceable, Debuggable, Swift.Error, Encodable {
    public static let readableName = "Vapor Error"
    public let identifier: String
    public var reason: String
    public var file: String
    public var function: String
    public var line: UInt
    public var column: UInt
    public var stackTrace: [String]
    
    init(
        identifier: String,
        reason: String,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.identifier = identifier
        self.reason = reason
        self.file = file
        self.function = function
        self.line = line
        self.column = column
        self.stackTrace = VaporError.makeStackTrace()
    }
    
    static func unknownMediaType(
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) -> VaporError {
        return VaporError(
            identifier: "unknownMediaType",
            reason: "Unable to parse Message contents from media type.",
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}




