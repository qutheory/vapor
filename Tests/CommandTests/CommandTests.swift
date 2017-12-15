import XCTest
import Command
import Console

class CommandTests: XCTestCase {
    func testExample() throws {
        let console = Terminal()
        let group = TestGroup()

        try! console.run(group, arguments: ["vapor", "sub", "test", "--help"])
        print(console.output)
        
        try! console.run(group, arguments: ["vapor", "--autocomplete"])
        print(console.output)
        
        try! console.run(group, arguments: ["vapor", "sub", "--autocomplete"])
        print(console.output)
        
        try! console.run(group, arguments: ["vapor", "sub", "test", "--autocomplete"])
        print(console.output)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
