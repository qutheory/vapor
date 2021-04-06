import NIO

extension HTTPClient {
    func delegating(to eventLoop: EventLoop, logger: Logger, byteBufferAllocator: ByteBufferAllocator) -> Client {
        EventLoopHTTPClient(
            http: self,
            eventLoop: eventLoop,
            logger: logger,
            byteBufferAllocator: byteBufferAllocator
        )
    }
}

private struct EventLoopHTTPClient: Client {
    let http: HTTPClient
    let eventLoop: EventLoop
    var logger: Logger?
    var byteBufferAllocator: ByteBufferAllocator

    func send(
        _ client: ClientRequest
    ) -> EventLoopFuture<ClientResponse> {
        do {
            let request = try HTTPClient.Request(
                url: URL(string: client.url.string)!,
                method: client.method,
                headers: client.headers,
                body: client.body.map { .byteBuffer($0) }
            )
            return self.http.execute(
                request: request,
                eventLoop: .delegate(on: self.eventLoop),
                logger: logger
            ).map { response in
                let client = ClientResponse(
                    status: response.status,
                    headers: response.headers,
                    body: response.body,
                    byteBufferAllocator: self.byteBufferAllocator
                )
                return client
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    func delegating(to eventLoop: EventLoop) -> Client {
        EventLoopHTTPClient(http: self.http, eventLoop: eventLoop, logger: self.logger, byteBufferAllocator: self.byteBufferAllocator)
    }

    func logging(to logger: Logger) -> Client {
        return EventLoopHTTPClient(http: self.http, eventLoop: self.eventLoop, logger: logger, byteBufferAllocator: self.byteBufferAllocator)
    }

    func allocating(to byteBufferAllocator: ByteBufferAllocator) -> Client {
        return EventLoopHTTPClient(http: self.http, eventLoop: self.eventLoop, logger: self.logger, byteBufferAllocator: byteBufferAllocator)
    }
}
