import XCTest
@testable import Vapor
import HTTP
import FormData
import Multipart

class FormDataTests: XCTestCase {
    static let allTests = [
        ("testHolistic", testHolistic),
    ]
    
    /**
        Test form data serialization and parsing
        for a text, html, and blob field.
    */
    func testHolistic() throws {
        let request = Request(method: .get, path: "form-data")
        
        let html = "<hello>"
        let htmlPart = Part(headers: [
            "foo": "bar"
        ], body: html.bytes)
        let htmlField = Field(name: "html", filename: "hello.html", part: htmlPart)
        
        let text = "If you're reading this, you've been in a coma for almost 20 years now. We're trying a new technique. We don't know where this message will end up in your dream, but we hope it works. Please wake up, we miss you."
        let textPart = Part(headers: [
            "vapor": "☁️"
        ], body: text.bytes)
        let textField = Field(name: "text", filename: nil, part: textPart)
        
        let garbageSize = 10_000_000
        
        var garbage = Bytes(repeating: Byte(0), count: garbageSize)
        
        for i in 0 ..< garbageSize {
            garbage[i] = Byte(Int.random(min: 0, max: 255))
        }
        
        let garbagePart = Part(headers: [:], body: garbage)
        let garbageField = Field(name: "garbage", filename: "社會科學.院", part: garbagePart)
        
        request.formData = [
            "html": htmlField,
            "text": textField,
            "garbage": garbageField
        ]
        
        let drop = Droplet(arguments: ["vapor", "serve"])
        
        drop.get("form-data") { req in
            guard let formData = req.formData else {
                XCTFail("No Form Data")
                throw Abort.badRequest
            }
            
            if let h = formData["html"] {
                XCTAssertEqual(h.string, html)
            } else {
                XCTFail("No html")
            }
            
            if let t = formData["text"] {
                XCTAssertEqual(t.string, text)
            } else {
                XCTFail("No text")
            }
            
            if let g = formData["garbage"] {
                XCTAssert(g.part.body == garbage)
            } else {
                XCTFail("No garbage")
            }
            
            return "👍"
        }
        
        try background {
            drop.run(servers: [
                "test": (host: "0.0.0.0", port: 8932, securityLayer: .none)
            ])
        }
        
        drop.console.wait(seconds: 1)
        
        let client = try drop.client.init(host: "0.0.0.0", port: 8932, securityLayer: .none, middleware: [])
        let response = try client.respond(to: request)
        
        XCTAssertEqual(try response.bodyString(), "👍")
    }
}
