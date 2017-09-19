import HTTP
import Routing
import Service

extension Services {
    /// The default Services included in the framework.
    public static func `default`() -> Services {
        var services = Services()

        // register engine server and default config settings
        services.register(Server.self) { container in
            return try EngineServer(
                config: container.make(for: EngineServer.self)
            )
        }
        services.register { container in
            return EngineServerConfig()
        }

        // register client
        services.register(Client.self) { container in
            return EngineClient()
        }

        // register middleware
        services.register { container in
            return MiddlewareConfig([
                DateMiddleware.self
            ])
        }
        services.register { container in
            return DateMiddleware()
        }
        services.register { container in
            return ErrorMiddleware()
        }

        // register router
        services.register([SyncRouter.self, AsyncRouter.self, Router.self]) { container in
            return TrieRouter()
        }

        return services
    }
}
