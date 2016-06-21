extension HTTPResponse {
    /**
        Convenience Initializer

        - parameter status: the http status
        - parameter json: any value that will be attempted to be serialized as json.  Use 'Json' for more complex objects
    */
    public convenience init(status: Status, json: JSON) {
        let headers: Headers = [
            "Content-Type": "application/json; charset=utf-8"
        ]
        self.init(status: status, headers: headers, body: HTTPBody(json))
    }
}
