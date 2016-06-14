import Foundation
import PathIndexable

private struct PrioritizedDirectoryQueue {
    let directories: [JSONDirectory]

    subscript(_ fileName: String, indexes: [PathIndex]) -> JSON? {
        return directories
            .lazy
            .flatMap { directory in return directory[fileName, indexes] }
            .first
    }
}

/**
    Parses and interprets configuration files
    included under Config in the working directory.

    Files stored in the Config directory can be accessed
    via `app.config["filename", "property"]`.

    For example, a file named `Config/app.json` containing
    `{"port": 80}` can be accessed with `app.config["app" "port"].int`.
    To override certain configurations for a given environment,
    create a file with the same name in a subdirectory of the environment.
    For example, a file named `Config/production/app.json` would override
    any properties in `Config/app.json` when the app is in production mode.

    Finally, Vapor supports sensitive environment specific information, such
    as API keys, to be stored in a special configuration folder at `Config/secrets`.
    This folder should be included in the `.gitignore` by default so that
    sensitive information does not get added to version control.
*/
public class Config {

    /**
        The environment loaded from `Environment.loader
    */
    public let environment: Environment

    private let configDirectory: String
    private let directoryQueue: PrioritizedDirectoryQueue

    /**
        Creates an instance of `Config` with
        starting configurations.
        The application is required to detect environment.
    */
    public init(
        seed: JSON = [:],
        workingDirectory: String = "./",
        environment: Environment? = nil,
        arguments: [String] = ProcessInfo.processInfo().arguments
    ) {
        let configDirectory = workingDirectory.finish("/") + "Config/"
        self.configDirectory = configDirectory
        self.environment = environment ?? Environment.loader(arguments: arguments)

        let seedFile = JSONFile(name: "app", json: seed)
        let seedDirectory = JSONDirectory(name: "seed-data", files: [seedFile])
        var prioritizedDirectories: [JSONDirectory] = [seedDirectory]

        // command line args passed w/ following syntax loaded first after seed
        // --config:app.port=9090
        // --config:passwords.mongo-user=user
        // --config:passwords.mongo-password=password
        // --config:<name>.<path>.<to>.<value>=<actual-value>
        let cliDirectory = Config.makeCLIConfig(arguments: arguments)
        prioritizedDirectories.insert(cliDirectory, at: 0) // should be most important

        // Json files are loaded in order of priority
        // it will go like this
        // paths will be searched for in top down order
        if let directory = FileManager.loadDirectory(configDirectory + "secrets") {
            prioritizedDirectories.append(directory)
        }
        if let directory = FileManager.loadDirectory(configDirectory + self.environment.description) {
            prioritizedDirectories.append(directory)
        }
        if let directory = FileManager.loadDirectory(configDirectory) {
            prioritizedDirectories.append(directory)
        }

        directoryQueue = PrioritizedDirectoryQueue(directories: prioritizedDirectories)
    }

    /**
         Use this to access config keys for specified file.
         For example, if I have a config file named 'metadata.json'
         that looks like this:

             {
                 "info" : {
                     "port" : 9090
                 }
             }

         You would access the port like this:

             let port = app.config["metadata", "info", "por"].int ?? 8080

         Follows format

             config[<json-file-name>, <path>, <to>, <value>

         - parameter file:  name of json file to look for
         - parameter paths: path to key

         - returns: value if it exists.
     */
    public subscript(_ file: String, _ paths: PathIndex...) -> Polymorphic? {
        return self[file, paths]
    }

    /**
         Splatting so that variadic can pass through here

         - parameter file:  name of json file to look for
         - parameter paths: path to key

         - returns: value if it exists.
     */
    public subscript(_ file: String, _ paths: [PathIndex]) -> Polymorphic? {
        return directoryQueue[file, paths]
    }
}

extension Environment {
    /**
        Used to load Environment automatically. Defaults to looking for `env` command line argument
     */
    static var loader: (arguments: [String]) -> Environment = { arguments in
        if let env = arguments.value(for: "env").flatMap(Environment.init(id:)) {
            Log.info("Environment override: \(env)")
            return env
        } else {
            return .development
        }
    }
}


extension String {
    private var keyPathComponents: [String] {
        return components(separatedBy: ".")
    }

}
