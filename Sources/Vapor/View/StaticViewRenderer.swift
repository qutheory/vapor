// FIXME: uncomment

//import Core
//import Foundation
//import Service
//
//public final class StaticViewRenderer: ViewRenderer {
//    let loader = FileManager()
//
//    public let viewsDir: String
//
//    public var shouldCache: Bool
//
//    public var cache: [String: View]?
//
//    public init(viewsDir: String) {
//        self.viewsDir = viewsDir.finished(with: "/")
//        shouldCache = false
//    }
//
//    public func make(_ path: String, _ data: ViewData) throws -> View
//        let path = path.hasPrefix("/") ? path : viewsDir + path
//        if shouldCache, let cached = cache?[path] { return cached }
//        let bytes = try loader.read(at: path)
//        let view = View(bytes: bytes)
//        cache?[path] = view
//        return view
//    }
//}
//
//// MARK: Service
//
//extension StaticViewRenderer: ServiceType {
//    /// See Service.name
//    public static var serviceName: String {
//        return "static"
//    }
//
//    /// See Service.serviceSupports
//    public static var serviceSupports: [Any.Type] {
//        return [ViewRenderer.self]
//    }
//
//    /// See Service.make
//    public static func makeService(for container: Container) throws -> Self? {
//        return .init(viewsDir: container.config.viewsDir)
//    }
//}

