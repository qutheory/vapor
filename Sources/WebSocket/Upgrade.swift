import HTTP
import Crypto

// MARK: Convenience

extension WebSocket {
    public typealias OnUpgradeClosure = (Request, WebSocket) throws -> Void

    /// Returns true if this request should upgrade to websocket protocol
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/websocket/upgrade/#determining-an-upgrade)	§
    public static func shouldUpgrade(for req: Request) -> Bool {
        return req.headers[.connection] == "Upgrade" && req.headers[.secWebSocketKey] != nil && req.headers[.secWebSocketVersion] != nil
    }
    
    /// Creates a websocket upgrade response for the upgrade request
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/websocket/upgrade/#upgrading-the-connection)
    public static func upgradeResponse(for request: Request,
                                       with settings: WebSocketSettings) throws -> Response {
        guard shouldUpgrade(for: request) else {
            throw WebSocketError(.invalidRequest)
        }

        try settings.apply(on: request)

        let headers = try buildWebSocketHeaders(for: request)
        let response = Response(status: 101, headers: headers)

        try settings.apply(on: response, request: request)

        return response
    }

    /// Creates a websocket upgrade response for the upgrade request
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/websocket/upgrade/#upgrading-the-connection)
    public static func upgradeResponse(for request: Request,
                                       with settings: WebSocketSettings,
                                       onUpgrade: @escaping OnUpgradeClosure) throws -> Response {
        let response = try upgradeResponse(for: request, with: settings)

        response.onUpgrade = { tcpClient in
            let websocket = WebSocket(socket: tcpClient)
            // Does it make sense to be defined here? If someone calls the above method, the websocket won't be set according to the given settings.
            try? settings.apply(on: websocket, request: request, response: response)

            try? onUpgrade(request, websocket)
        }

        return response
    }

    private static func buildWebSocketHeaders(for req: Request) throws -> Headers {
        guard
            req.method == .get,
            let key = req.headers[.secWebSocketKey],
            let secWebsocketVersion = req.headers[.secWebSocketVersion],
            let version = Int(secWebsocketVersion)
            else {
                throw WebSocketError(.invalidRequest)
        }

        let data = Base64Encoder.encode(data: SHA1.hash(key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
        let hash = String(bytes: data, encoding: .utf8) ?? ""

        var headers: Headers = [
            .upgrade: "websocket",
            .connection: "Upgrade",
            .secWebSocketAccept: hash
        ]

        guard version > 13 else {
            return headers
        }

        headers[.secWebSocketVersion] = "13"
        return headers
    }
}

