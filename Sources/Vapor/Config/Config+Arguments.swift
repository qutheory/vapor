//import Foundation
//import Service
//
//extension Config {
//    /// CLI Config expects arguments to have the following syntax:
//    ///
//    /// --config: <key-path> = <value>
//    ///
//    /// For example
//    ///
//    /// --config:database.user=some-user
//    ///
//    /// Will be accessible as
//    ///
//    /// config["database", "user"] // some-user
//    internal static func makeCLIConfig(arguments: [String] = CommandLine.arguments) -> Config {
//        let configArgs = arguments.filter { $0.hasPrefix("--config") }
//
//        // [FileName: Node]
//        var cli = [String: Config]()
//
//        configArgs.forEach { arg in
//            guard
//                let (key, value) = parseInput(arg),
//                let (name, path) = parseConfigKey(key)
//                else { return }
//
//            var argument = Config()
//
//            if path.isEmpty {
//                argument = .string(value)
//            } else {
//                argument[path] = .string(value)
//            }
//
//            cli[name] = argument
//        }
//
//        return .dictionary(cli)
//    }
//
//    private static func parseInput(_ arg: String) -> (key: String, value: String)? {
//        let info = arg
//            .characters
//            .split(separator: "=",
//                   maxSplits: 1,
//                   omittingEmptySubsequences: true)
//            .map(String.init)
//
//        return info.first.flatMap { key in
//            // Keys like --config:release default to `release = true`
//            let value = info[safe: 1] ?? "true"
//            return (key, value)
//        }
//    }
//
//    private static func parseConfigKey(_ key: String) -> (name: String, path: [String])? {
//        // --config:drop.port
//        // expect [--config, drop.port]
//        let path = key
//            .characters
//            .split(separator: ":",
//                   maxSplits: 1,
//                   omittingEmptySubsequences: true)
//            .map(String.init)
//            .last?
//            .components(separatedBy: ".")
//
//        return path.flatMap { path in
//            return path[safe: 0].flatMap { name in
//                return (name, path.dropFirst().array)
//            }
//        }
//    }
//}

