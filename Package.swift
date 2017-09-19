// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Vapor",
    products: [
        // Core
        .library(name: "Core", targets: ["Core"]),
        .library(name: "libc", targets: ["libc"]),

        // Crypto
        .library(name: "Crypto", targets: ["Crypto"]),

        // Debugging
        .library(name: "Debugging", targets: ["Debugging"]),

        // Leaf
        .library(name: "JWT", targets: ["JWT"]),

        // Leaf
        .library(name: "Leaf", targets: ["Leaf"]),

        // Leaf
        .library(name: "Logging", targets: ["Logging"]),

        // MySQL
        .library(name: "MySQL", targets: ["MySQL"]),

        // Net
        .library(name: "HTTP", targets: ["HTTP"]),
        .library(name: "TCP", targets: ["TCP"]),

        // Routing
        .library(name: "Routing", targets: ["Routing"]),

        // Service
        .library(name: "Service", targets: ["Service"]),

        // TLS
        .library(name: "TLS", targets: ["TLS"]),

        // Vapor
        .library(name: "Vapor", targets: ["Vapor"]),
        
        // WebSockets
        .library(name: "WebSocket", targets: ["WebSocket"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/ctls.git", from: "1.1.2")
    ],
    targets: [
        // Core
        .target(name: "Core", dependencies: ["libc", "Debugging"]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .target(name: "libc"),

        // Crypto
        .target(name: "Crypto", dependencies: ["Core"]),
        .testTarget(name: "CryptoTests", dependencies: ["Crypto"]),

        // Debugging
        .target(name: "Debugging"),
        .testTarget(name: "DebuggingTests", dependencies: ["Debugging"]),

        // JWT
        .target(name: "JWT", dependencies: ["Crypto"]),
        .testTarget(name: "JWTTests", dependencies: ["JWT"]),

        // Leaf
        .target(name: "Leaf", dependencies: ["Core", "Service"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf"]),

        // Logging
        .target(name: "Logging", dependencies: ["Core", "Service"]),
        .testTarget(name: "LoggingTests", dependencies: ["Logging"]),

        // MySQL
        .target(name: "MySQL", dependencies: ["TCP", "Crypto"]),
        .testTarget(name: "MySQLTests", dependencies: ["MySQL"]),

        // Net
        .target(name: "CHTTP"),
        .target(name: "HTTP", dependencies: ["CHTTP", "TCP"]),
        .testTarget(name: "HTTPTests", dependencies: ["HTTP"]),
        .target(name: "TCP", dependencies: ["Debugging", "Core", "libc"]),
        .testTarget(name: "TCPTests", dependencies: ["TCP"]),

        // Routing
        .target(name: "Routing", dependencies: ["Core", "Debugging", "HTTP", "WebSocket"]),
        .testTarget(name: "RoutingTests", dependencies: ["Routing"]),

        // Service
        .target(name: "Service", dependencies: ["Core", "Debugging"]),
        .testTarget(name: "ServiceTests", dependencies: ["Service"]),

        // TLS
        .target(name: "TLS", dependencies: ["CTLS", "Debugging"]),
        .testTarget(name: "TLSTests", dependencies: ["TLS"]),

        // Vapor
        .target(name: "Development", dependencies: ["Leaf", "Vapor", "MySQL"]),
        .target(name: "Vapor", dependencies: [
            "Core",
            "Debugging",
            "HTTP",
            "Leaf",
            "Routing",
            "Service",
            "TCP",
            "WebSocket",
        ]),
        .testTarget(name: "VaporTests", dependencies: ["Vapor"]),

        // WebSocket
        .target(name: "WebSocket", dependencies: ["Core", "Debugging", "TCP", "HTTP", "Crypto"]),
        .testTarget(name: "WebSocketTests", dependencies: ["WebSocket"]),
    ]
)
