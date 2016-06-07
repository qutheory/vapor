//
//  RouterTests.swift
//  Vapor
//
//  Created by Tanner Nelson on 2/18/16.
//  Copyright © 2016 Tanner Nelson. All rights reserved.
//

import Foundation
import XCTest
@testable import Vapor

class RouterTests: XCTestCase {

    static var allTests: [(String, (RouterTests) -> () throws -> Void)] {
        return [
           ("testSingleHostRouting", testSingleHostRouting),
           ("testMultipleHostsRouting", testMultipleHostsRouting),
           ("testURLParameterDecoding", testURLParameterDecoding)
        ]
    }

    func testSingleHostRouting() {
        let router = BranchRouter()
        let compare = "Hello Text Data Processing Test"
        let data = Data(compare.utf8)

        let route = Route.init(host: "other.test", method: .get, path: "test") { request in
            return Response(status: .ok, headers: [:], data: data)
        }
        router.register(route)

        let request = Request(method: .get, path: "test", host: "other.test")

        do {
            guard let result = router.route(request) else {
                XCTFail("no route found")
                return
            }

            let body = try result(request).makeResponse().body

            if case .buffer(let data) = body {
                XCTAssert(compare.data == data)
            } else {
                XCTFail("Body was not buffer")
            }
        } catch {
            XCTFail()
        }
    }

    func testMultipleHostsRouting() {
        let router = BranchRouter()

        let data_1 = "1".data
        let data_2 = "2".data

        let route_1 = Route.init(method: .get, path: "test") { request in
            return Response(status: .ok, data: data_1)
        }
        router.register(route_1)

        let route_2 = Route.init(host: "vapor.test", method: .get, path: "test") { request in
            return Response(status: .ok, data: data_2)
        }
        router.register(route_2)

        let request_1 = Request(method: .get, path: "test", host: "other.test")

        let request_2 = Request(method: .get, path: "test", host: "vapor.test")

        let handler_1 = router.route(request_1)
        let handler_2 = router.route(request_2)

        if let response_1 = try? handler_1?(request_1) {
            let body = response_1!.makeResponse().body
            if case .buffer(let data) = body {
                XCTAssert(data == data_1, "Incorrect response returned by Handler 1")
            } else {
                XCTFail("Body was not buffer")
            }
        } else {
            XCTFail("Handler 1 did not return a response")
        }

        if let response_2 = try? handler_2?(request_2) {
            let body = response_2!.makeResponse().body
            if case .buffer(let data) = body {
                XCTAssert(data == data_2, "Incorrect response returned by Handler 2")
            } else {
                XCTFail("Body was not buffer")
            }
        } else {
            XCTFail("Handler 2 did not return a response")
        }
    }

    func testURLParameterDecoding() {
        let router = BranchRouter()

        let percentEncodedString = "testing%20parameter%21%23%24%26%27%28%29%2A%2B%2C%2F%3A%3B%3D%3F%40%5B%5D"
        let decodedString = "testing parameter!#$&'()*+,/:;=?@[]"

        var handlerRan = false

        let route = Route(method: .get, path: "test/:string") { request in

            let testParameter = request.parameters["string"]
            print(request.parameters)
            print("hi")

            XCTAssert(testParameter == decodedString, "URL parameter was not decoded properly")

            handlerRan = true

            return Response(status: .ok, data: [])
        }
        router.register(route)

        let request = Request(method: .get, path: "test/\(percentEncodedString)")
        guard let handler = router.route(request) else {
            XCTFail("Route not found")
            return
        }

        do {
            let _ = try handler(request)
        } catch {
            XCTFail("Handler threw error \(error)")
        }

        XCTAssert(handlerRan, "The handler did not run, and the parameter test also did not run")
    }

}
