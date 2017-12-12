import Async
import Console
import JunkDrawer
import Dispatch
import HTTP
import Foundation
import Routing
import Service
import TLS

#if os(Linux)
    import OpenSSL
    let defaultSSLClient = OpenSSLClient.self
    let defaultSSLClientUpgrader = OpenSSLClientUpgrader.self
    let defaultSSLPeerUpgrader = OpenSSLPeerUpgrader.self
#else
    import AppleSSL
    let defaultSSLClient = AppleSSLClient.self
    let defaultSSLClientUpgrader = AppleSSLClientUpgrader.self
    let defaultSSLPeerUpgrader = AppleSSLPeerUpgrader.self
#endif

extension Services {
    /// The default Services included in the framework.
    public static func `default`() -> Services {
        var services = Services()

        // register engine server and default config settings
        services.register(Server.self) { container in
            return try EngineServer(
                config: container.make(for: EngineServer.self),
                container: container
            )
        }
        
        services.register { container in
            return EngineServerConfig()
        }
        
        services.register(SSLClientSettings.self) { _ in
            return SSLClientSettings()
        }
        
        services.register(SSLClientUpgrader.self) { _ in
            return defaultSSLClientUpgrader.init()
        }
        
        services.register(SSLPeerUpgrader.self) { _ in
            return defaultSSLPeerUpgrader.init()
        }
        
        services.register(BasicSSLClient.self) { container -> BasicSSLClient in
            let client = try defaultSSLClient.init(
                settings: try container.make(for: SSLClientSettings.self),
                on: container
            )
            
            return BasicSSLClient(boxing: client)
        }

        services.register(Client.self) { container -> EngineClient in
            if let sub = container as? SubContainer {
                /// if a request is creating a client, we should
                /// use the event loop as the container
                return EngineClient(container: sub.superContainer)
            } else {
                return EngineClient(container: container)
            }
        }

        // register middleware
        services.register { container -> MiddlewareConfig in
            var config = MiddlewareConfig()
            config.use(FileMiddleware.self)
            config.use(DateMiddleware.self)
            config.use(ErrorMiddleware.self)
            return config
        }

        services.register { container -> FileMiddleware in
            let directory = try container.make(DirectoryConfig.self, for: FileMiddleware.self)
            return FileMiddleware(publicDirectory: directory.workDir + "Public/")
        }
        
        services.register { container in
            return DateMiddleware()
        }
        
        services.register { worker in
            return try ErrorMiddleware(environment: worker.environment, log: worker.make(for: ErrorMiddleware.self))
        }

        // register router
        services.register(Router.self, isSingleton: true) { container in
            return EngineRouter.default()
        }

        // register content coders
        services.register { container in
            return ContentConfig.default()
        }
        
        // register transfer encodings
        services.register { container in
            return TransferEncodingConfig.default()
        }

        services.register([FileReader.self, FileCache.self]) { container in
            return File(queue: container.queue)
        }

        // register terminal console
        services.register(Console.self) { container in
            return Terminal()
        }
        services.register(Responder.self) { container in
            return try RouterResponder(
                router: container.make(for: Responder.self)
            )
        }

        services.register { worker -> ServeCommand in
            let responder = try worker.make(Responder.self, for: ServeCommand.self)

            let middleware = try worker
                .make(MiddlewareConfig.self, for: ServeCommand.self)
                .resolve(for: worker)

            return try ServeCommand(
                server: worker.make(for: ServeCommand.self),
                responder: middleware.makeResponder(chainedto: responder)
            )
        }
        services.register { container -> CommandConfig in
            return CommandConfig.default()
        }
        services.register { container -> RoutesCommand in
            return try RoutesCommand(
                router: container.make(for: RoutesCommand.self)
            )
        }

        // worker
        services.register { container -> EphemeralWorkerConfig in
            let config = EphemeralWorkerConfig()
            config.add(Request.self)
            config.add(Response.self)
            return config
        }

        // directory
        services.register { container -> DirectoryConfig in
            return DirectoryConfig.default()
        }

        // logging
        services.register(Logger.self) { container -> ConsoleLogger in
            return try ConsoleLogger(
                console: container.make(for: ConsoleLogger.self)
            )
        }
        services.register(Logger.self) { container -> PrintLogger in
            return PrintLogger()
        }

        return services
    }
}
