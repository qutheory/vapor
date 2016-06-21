/**
    Any data structure that complies to this protocol
    can be returned to generic Vapor closures or route handlers.

    ```app.get("/") { request in
        return object //must be of type `ResponseRepresentable`
    }```
*/
public protocol ResponseRepresentable {
    func makeResponse() throws -> HTTPResponse
}

///Allows responses to be returned through closures
extension HTTPResponse: ResponseRepresentable {
    public func makeResponse() -> HTTPResponse {
        return self
    }
}

///Allows Swift Strings to be returned through closures
extension Swift.String: ResponseRepresentable {
    public func makeResponse() -> HTTPResponse {
        let data = self.utf8.array
        return HTTPResponse(body: .data(data))
    }
}
