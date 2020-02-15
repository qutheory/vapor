import Vapor
import XCTest

class LoggingTests : XCTestCase {

    func testNotFoundLogging() throws {
        
        var services = Services.default()
        var config = Config.default()
        let loggerProvider = TestLoggerProvider()
                
        try services.register(loggerProvider)
        config.prefer(TestLogger.self, for: Logger.self)
        
        let app = try Application(config: config, services: services)

        let req = Request(
            http: HTTPRequest(method: .GET, url: "/hello/vapor"),
            using: app
        )
        
        do {
            _ = try app.make(Responder.self).respond(to: req).wait()
        } catch {}
        
        XCTAssert(loggerProvider.logger.didLog(string: "Abort.404: GET /hello/vapor Not Found"))
    }
    
    func testInternalServerErrorLogging() throws {
        
        var services = Services.default()
        var config = Config.default()
        let loggerProvider = TestLoggerProvider()
                
        try services.register(loggerProvider)
        config.prefer(TestLogger.self, for: Logger.self)
        
        let router = EngineRouter.default()
    
        router.post("fail/me") { (_) -> String in
            throw Abort(.internalServerError)
        }
        
        services.register(router, as: Router.self)
        
        let app = try Application(config: config, services: services)
        
        let req = Request(
            http: HTTPRequest(method: .POST, url: "/fail/me"),
            using: app
        )
        
        do {
            _ = try app.make(Responder.self).respond(to: req).wait()
        } catch {}
        
        XCTAssert(loggerProvider.logger.didLog(string: "Abort.500: POST /fail/me Internal Server Error"))
    }
    
    static let allTests = [
        ("testNotFoundLogging", testNotFoundLogging),
        ("testInternalServerErrorLogging", testInternalServerErrorLogging)
    ]
}
