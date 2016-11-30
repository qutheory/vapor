import Routing
import HTTP
import TypeSafeRouting

public final class Resource<Model: StringInitializable> {
    public typealias SimpleRequest = (Request) throws -> ResponseRepresentable
    public typealias ItemRequest = (Request, Model) throws -> ResponseRepresentable

    public var index: SimpleRequest?
    public var new: SimpleRequest?
    public var create: SimpleRequest?
    public var show: ItemRequest?
    public var update: ItemRequest?
    public var replace: ItemRequest?
    public var destroy: ItemRequest?
    public var clear: SimpleRequest?
    public var aboutItem: ItemRequest?
    public var aboutSimple: SimpleRequest?

    public init(
        index: SimpleRequest? = nil,
        new: SimpleRequest? = nil,
        create: SimpleRequest? = nil,
        show: ItemRequest? = nil,
        replace: ItemRequest? = nil,
        update: ItemRequest? = nil,
        destroy: ItemRequest? = nil,
        clear: SimpleRequest? = nil,
        aboutItem: ItemRequest? = nil,
        aboutSimple: SimpleRequest? = nil
        ) {
        self.index = index
        self.new = new
        self.create = create
        self.show = show
        self.replace = replace
        self.update = update
        self.destroy = destroy
        self.clear = clear
        self.aboutItem = aboutItem
        self.aboutSimple = aboutSimple
    }
}

public protocol ResourceRepresentable {
    associatedtype Model: StringInitializable
    func makeResource() -> Resource<Model>
}

extension RouteBuilder where Value == Responder {
    public func resource<Resource: ResourceRepresentable>(_ path: String, _ resource: Resource) {
        let resource = resource.makeResource()
        self.resource(path, resource)
    }

    public func resource<Model: StringInitializable>(_ path: String, _ resource: Resource<Model>) {
        var itemMethods: [Method] = []
        var simpleMethods: [Method] = []

        func item(_ method: Method, _ item: Resource<Model>.ItemRequest?) {
            guard let item = item else {
                return
            }

            itemMethods += method

            self.add(method, path, ":id") { request in
                guard let id = request.parameters["id"]?.string else {
                    throw Abort.notFound
                }

                guard let model = try Model(from: id) else {
                    throw Abort.notFound
                }

                return try item(request, model).makeResponse()
            }
        }

        func simple(_ method: Method, subpath: String? = nil, _ simple: Resource<Model>.SimpleRequest?) {
            guard let simple = simple else {
                return
            }

            simpleMethods += method

            if let subpath = subpath {
                self.add(method, path, subpath) { request in
                    return try simple(request).makeResponse()
                }
            } else {
                self.add(method, path) { request in
                    return try simple(request).makeResponse()
                }
            }
        }

        simple(.get, resource.index)
        simple(.get, subpath: "new", resource.new)
        simple(.post, resource.create)
        item(.get, resource.show)
        item(.put, resource.replace)
        item(.patch, resource.update)
        item(.delete, resource.destroy)
        simple(.delete, resource.clear)

        if let about = resource.aboutItem {
            item(.options, about)
        } else {
            item(.options) { request in
                return try JSON(node: [
                    "resource": "\(path)/:id",
                    "methods": try JSON(node: itemMethods.map { $0.description })
                    ])
            }
        }

        if let about = resource.aboutSimple {
            simple(.options, about)
        } else {
            simple(.options) { request in
                let methods: [String] = simpleMethods.map { $0.description }
                return try JSON(node: [
                    "resource": path,
                    "methods": try JSON(node: methods)
                    ])
            }
        }
    }

    public func resource<Model: StringInitializable>(
        _ path: String,
        _ type: Model.Type = Model.self,
        closure: (Resource<Model>) -> ()
        ) {
        let resource = Resource<Model>()
        closure(resource)
        self.resource(path, resource)
    }
}
