/**
    Loads and renders a file from the `Resources` folder
    in the Application's work directory.
*/
public class View {
    ///Currently applied RenderDrivers
    public static var renderers: [String: RenderDriver] = [:]

    var data: Data

    enum Error: ErrorProtocol {
        case InvalidPath
    }

    /**
        Attempt to load and render a file
        from the supplied path using the contextual
        information supplied.
        - context Passed to RenderDrivers
    */
    public init(application: Application, path: String, context: [String: Any] = [:]) throws {
        let filesPath = application.workDir + "Resources/Views/" + path

        guard let fileBody = try? FileManager.readBytesFromFile(filesPath) else {
            self.data = Data()
            Log.error("No view found in path: \(filesPath)")
            throw Error.InvalidPath
        }
        self.data = Data(fileBody)

        for (suffix, renderer) in View.renderers {
            if path.hasSuffix(suffix) {
                let template = try String(data: data)
                let rendered = try renderer.render(template: template, context: context)
                self.data = rendered.data
            }
        }

    }

}

///Allows Views to be returned in Vapor closures
extension View: ResponseRepresentable {
    public func makeResponse() -> Response {
        return Response(status: .ok, headers: [
            "Content-Type": "text/html"
        ], data: data)
    }
}

///Adds convenience method to Application to create a view
extension Application {

    /**
        Views directory relative to Application.resourcesDir
    */
    public var viewsDir: String {
        return resourcesDir + "Views/"
    }

    /**
     Loads a view with a given context

     - parameter path: the path to the view
     - parameter context: the context to use when loading the view

     - throws: an error if loading fails
     */
    public func view(_ path: String, context: [String: Any] = [:]) throws -> View {
        return try View(application: self, path: path, context: context)
    }

}
