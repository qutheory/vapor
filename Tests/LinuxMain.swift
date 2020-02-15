#if os(Linux)

import XCTest
@testable import VaporTests

XCTMain([
    // Vapor
    testCase(ApplicationTests.allTests),
    testCase(MiddlewareTests.allTests),
    testCase(LoggingTests.allTests)
])

#endif
