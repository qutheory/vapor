import Vapor

let app = Application()

app.get("plaintext") { request in
    return Response(data: Data("Hello, world!".utf8))
}

app.post("data") { request in
    return "data"
}

app.start()
