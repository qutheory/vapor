import Core
import Debugging
import HTTP
import Routing
import Service

fileprivate let errorView = ErrorView()

/// Catches errors and converts them into responses
/// which a description of the error.
public final class ErrorMiddleware: Middleware {
    let log: LogProtocol
    let environment: Environment
    public init(environment: Environment, log: LogProtocol) {
        self.log = log
        self.environment = environment
    }
    
    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        do {
            return try next.respond(to: req)
        } catch {
            try log.swiftError(error)
            return try make(with: req, for: error)
        }
    }
    
    public func make(with req: Request, for error: Error) throws -> Response {
        guard !req.accept.prefers("html") else {
            let status: Status = Status(error)
            let bytes = errorView.render(
                code: status.statusCode,
                message: status.reasonPhrase
            )
            return View(bytes: bytes).makeResponse()
        }
        
        let status = Status(error)
        let response = Response(status: status)

        let info = DebugInformation(error, env: environment)
        try response.content(info)

        return response
    }
}

extension ErrorMiddleware: ServiceType {
    /// See Service.name
    public static var serviceName: String {
        return "error"
    }

    /// See Service.serviceSupports
    public static var serviceSupports: [Any.Type] {
        return [Middleware.self]
    }

    /// See Service.make
    public static func makeService(for container: Container) throws -> ErrorMiddleware? {
        return try ErrorMiddleware(
            environment: container.environment,
            log: container.make()
        )
    }
}

extension Status {
    internal init(_ error: Error) {
        if let abort = error as? AbortError {
            self = abort.status
        } else {
            self = .internalServerError
        }
    }
}

fileprivate struct DebugInformation: JSONEncodable, ContentEncodable {
    var error = true
    var reason: String
    var metadata: [String: String]?

    // debugging
    var debugReason: String?
    var identifier: String?
    var possibleCauses: [String]?
    var suggestedFixes: [String]?
    var documentationLinks: [String]?
    var stackOverflowQuestions: [String]?
    var gitHubIssues: [String]?

    fileprivate init(_ error: Error, env: Environment) {
        let status = Status(error)

        if let abort = error as? AbortError {
            reason = abort.reason
        } else {
            reason = status.reasonPhrase
        }
        
        guard env != .production else {
            return
        }

        if let abort = error as? AbortError {
            metadata = abort.metadata
        }

        if let debug = error as? Debuggable {
            debugReason = debug.reason
            identifier = debug.fullIdentifier
        }

        if let help = error as? Helpable {
            possibleCauses = help.possibleCauses
            suggestedFixes = help.suggestedFixes
            documentationLinks = help.documentationLinks
            stackOverflowQuestions = help.stackOverflowQuestions
            gitHubIssues = help.gitHubIssues
        }
    }
}

extension RouterError: AbortError {
    public var status: Status {
        return .notFound
    }

    public var reason: String {
        return Status.notFound.reasonPhrase
    }

    public var metadata: [String: String]? {
        return nil
    }
}

extension LogProtocol {
    public func swiftError(_ error: Error) throws {
        if let debuggable = error as? Debuggable {
            try self.error(debuggable.debuggableHelp(format: .short))
        } else {
            let type = String(reflecting: Swift.type(of: error))
            try self.error("[\(type): \(error)]")
            try info("Conform '\(type)' to Debugging.Debuggable to provide more debug information.")
        }
    }
}
