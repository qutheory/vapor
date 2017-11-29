import Async
import Core
import Dispatch
import Leaf
import Service
import XCTest

class LeafTests: XCTestCase {
    var renderer: LeafRenderer!
    var queue: Worker!

    override func setUp() {
        self.queue = EventLoop(queue: DispatchQueue(label: "codes.vapor.leaf.test"))
        self.renderer = LeafRenderer.makeTestRenderer(worker: queue)
    }

    func testRaw() throws {
        let template = "Hello!"
        try XCTAssertEqual(renderer.render(template, context: .null, on: queue).blockingAwait(), "Hello!")
    }

    func testPrint() throws {
        let template = "Hello, #(name)!"
        let data = LeafData.dictionary(["name": .string("Tanner")])
        try XCTAssertEqual(renderer.render(template, context: data, on: queue).blockingAwait(), "Hello, Tanner!")
    }

    func testConstant() throws {
        let template = "<h1>#(42)</h1>"
        try XCTAssertEqual(renderer.render(template, context: .null, on: queue).blockingAwait(), "<h1>42</h1>")
    }

    func testInterpolated() throws {
        let template = """
        <p>#("foo: #(foo)")</p>
        """
        let data = LeafData.dictionary(["foo": .string("bar")])
        try XCTAssertEqual(renderer.render(template, context: data, on: queue).blockingAwait(), "<p>foo: bar</p>")
    }

    func testNested() throws {
        let template = """
        <p>#(embed(foo))</p>
        """
        let data = LeafData.dictionary(["foo": .string("bar")])
        try XCTAssertEqual(renderer.render(template, context: data, on: queue).blockingAwait(), "<p>Test file name: &quot;/bar.leaf&quot;</p>")
    }

    func testExpression() throws {
        let template = "#(age > 99)"

        let young = LeafData.dictionary(["age": .int(21)])
        let old = LeafData.dictionary(["age": .int(150)])
        try XCTAssertEqual(renderer.render(template, context: young, on: queue).blockingAwait(), "false")
        try XCTAssertEqual(renderer.render(template, context: old, on: queue).blockingAwait(), "true")
    }

    func testBody() throws {
        let template = """
        #if(show) {hi}
        """
        let noShow = LeafData.dictionary(["show": .bool(false)])
        let yesShow = LeafData.dictionary(["show": .bool(true)])
        try XCTAssertEqual(renderer.render(template, context: noShow, on: queue).blockingAwait(), "")
        try XCTAssertEqual(renderer.render(template, context: yesShow, on: queue).blockingAwait(), "hi")
    }

    func testRuntime() throws {
        // FIXME: need to run var/exports first and in order
        let template = """
            #var("foo", "bar")
            Runtime: #(foo)
        """

        let res = try renderer.render(template, context: .dictionary([:]), on: queue).blockingAwait()
        print(res)
        XCTAssert(res.contains("Runtime: bar"))
    }

    func testEmbed() throws {
        let template = """
            #embed("hello")
        """
        try XCTAssert(renderer.render(template, context: .null, on: queue).blockingAwait().contains("hello.leaf"))
    }

    func testError() throws {
        do {
            let template = "#if() { }"
            _ = try renderer.render(template, context: .null, on: queue).blockingAwait()
        } catch {
            print("\(error)")
        }

        do {
            let template = """
            Fine
            ##bad()
            Good
            """
            _ = try renderer.render(template, context: .null, on: queue).blockingAwait()
        } catch {
            print("\(error)")
        }

        renderer.render(path: "##()", context: .null, on: queue).do { data in
            print(data)
            // FIXME: check for error
        }.catch { error in
            print("\(error)")
        }

        do {
            _ = try renderer.render("#if(1 == /)", context: .null, on: queue).blockingAwait()
        } catch {
            print("\(error)")
        }
    }

    func testChained() throws {
        let template = """
        #ifElse(false) {

        } ##ifElse(false) {

        } ##ifElse(true) {It works!}
        """
        try XCTAssertEqual(renderer.render(template, context: .null, on: queue).blockingAwait(), "It works!")
    }

    func testForSugar() throws {
        let template = """
        <p>
            <ul>
                #for(name in names) {
                    <li>#(name)</li>
                }
            </ul>
        </p>
        """

        let context = LeafData.dictionary([
            "names": .array([
                .string("Vapor"), .string("Leaf"), .string("Bits")
            ])
        ])

        let expect = """
        <p>
            <ul>
                <li>Vapor</li>
                <li>Leaf</li>
                <li>Bits</li>
            </ul>
        </p>
        """
        try XCTAssertEqual(renderer.render(template, context: context, on: queue).blockingAwait(), expect)
    }

    func testIfSugar() throws {
        let template = """
        #if(false) {Bad} else if (true) {Good} else {Bad}
        """
        try XCTAssertEqual(renderer.render(template, context: .null, on: queue).blockingAwait(), "Good")
    }

    func testCommentSugar() throws {
        let template = """
        #("foo")
        #// this is a comment!
        bar
        """

        let multilineTemplate = """
        #("foo")
        #/*
            this is a comment!
        */
        bar
        """
        try XCTAssertEqual(renderer.render(template, context: .null, on: queue).blockingAwait(), "foobar")
        try XCTAssertEqual(renderer.render(multilineTemplate, context: .null, on: queue).blockingAwait(), "foo\nbar")
    }

    func testHashtag() throws {
        let template = """
        #("hi") #thisIsNotATag...
        """
        try XCTAssertEqual(renderer.render(template, context: .null, on: queue).blockingAwait(), "hi #thisIsNotATag...")
    }

    func testNot() throws {
        let template = """
        #if(!false) {Good} #if(!true) {Bad}
        """

        try XCTAssertEqual(renderer.render(template, context: .null, on: queue).blockingAwait(), "Good")
    }

    func testFuture() throws {
        let template = """
        #if(false) {
            #(foo)
        }
        """

        var didAccess = false
        let context = LeafData.dictionary([
            "foo": .lazy({
                didAccess = true
                return .string("hi")
            })
        ])

        try XCTAssertEqual(renderer.render(template, context: context, on: queue).blockingAwait(), "")
        XCTAssertEqual(didAccess, false)
    }

    func testNestedBodies() throws {
        let template = """
        #if(true) {#if(true) {Hello\\}}}
        """
        try XCTAssertEqual(renderer.render(template, context: .null, on: queue).blockingAwait(), "Hello}")
    }

    func testDotSyntax() throws {
        let template = """
        #if(user.isAdmin) {Hello, #(user.name)!}
        """

        let context = LeafData.dictionary([
            "user": .dictionary([
                "isAdmin": .bool(true),
                "name": .string("Tanner")
            ])
        ])
        try XCTAssertEqual(renderer.render(template, context: context, on: queue).blockingAwait(), "Hello, Tanner!")
    }

    func testEqual() throws {
        let template = """
        #if(user.id == 42) {User 42!} #if(user.id != 42) {Shouldn't show up}
        """

        let context = LeafData.dictionary([
            "user": .dictionary([
                "id": .int(42),
                "name": .string("Tanner")
            ])
        ])
        try XCTAssertEqual(renderer.render(template, context: context, on: queue).blockingAwait(), "User 42!")
    }

    func testEscapeExtraneousBody() throws {
        let template = """
        extension #("User") \\{

        }
        """
        let expected = """
        extension User {

        }
        """
        try XCTAssertEqual(renderer.render(template, context: .null, on: queue).blockingAwait(), expected)
    }


    func testEscapeTag() throws {
        let template = """
        #("foo") \\#("bar")
        """
        let expected = """
        foo #("bar")
        """
        try XCTAssertEqual(renderer.render(template, context: .null, on: queue).blockingAwait(), expected)
    }

    func testIndentationCorrection() throws {
        let template = """
        <p>
            <ul>
                #for(item in items) {
                    #if(true) {
                        <li>#(item)</li>
                        <br>
                    }
                }
            </ul>
        </p>
        """

        let expected = """
        <p>
            <ul>
                <li>foo</li>
                <br>
                <li>bar</li>
                <br>
                <li>baz</li>
                <br>
            </ul>
        </p>
        """

        let context: LeafData = .dictionary([
            "items": .array([.string("foo"), .string("bar"), .string("baz")])
        ])

        try XCTAssertEqual(renderer.render(template, context: context, on: queue).blockingAwait(), expected)
    }

    func testAsyncExport() throws {
        let preloaded = PreloadedFiles()

        preloaded.files["/template.leaf"] = """
        Content: #raw(content)
        """.data(using: .utf8)!

        preloaded.files["/nested.leaf"] = """
        Nested!
        """.data(using: .utf8)!

        let template = """
        #export("content") {<p>#import("nested")</p>}
        #import("template")
        """

        let expected = """
        Content: <p>Nested!</p>
        """

        let config = LeafConfig(tags: defaultTags) { _ in
            return preloaded
        }
        
        let renderer = LeafRenderer(config: config, worker: queue)
        try XCTAssertEqual(renderer.render(template, context: .dictionary([:]), on: queue).blockingAwait(), expected)
    }

    func testService() throws {
        var services = Services()
        try services.register(LeafProvider())

        services.register { container in
            return LeafConfig(tags: defaultTags, viewsDir: "/") { queue in
                TestFiles()
            }
        }

        let container = BasicContainer(services: services)

        let config = try container.make(LeafConfig.self, for: XCTest.self)
        let view = LeafRenderer(config: config, worker: queue)

        struct TestContext: Encodable {
            var name = "test"
        }
        let rendered = try view.make(
            "foo", context: TestContext(),
            on: queue
        ).blockingAwait()

        let expected = """
        Test file name: "/foo.leaf"
        """

        XCTAssertEqual(String(data: rendered.data, encoding: .utf8), expected)
    }

    static var allTests = [
        ("testPrint", testPrint),
        ("testConstant", testConstant),
        ("testInterpolated", testInterpolated),
        ("testNested", testNested),
        ("testExpression", testExpression),
        ("testBody", testBody),
        ("testRuntime", testRuntime),
        ("testEmbed", testEmbed),
        ("testChained", testChained),
        ("testIfSugar", testIfSugar),
        ("testCommentSugar", testCommentSugar),
        ("testHashtag", testHashtag),
        ("testNot", testNot),
        ("testFuture", testFuture),
        ("testNestedBodies", testNestedBodies),
        ("testDotSyntax", testDotSyntax),
        ("testEqual", testEqual),
        ("testEscapeExtraneousBody", testEscapeExtraneousBody),
        ("testEscapeTag", testEscapeTag),
        ("testIndentationCorrection", testIndentationCorrection),
        ("testAsyncExport", testAsyncExport),
        ("testService", testService),
    ]
}
