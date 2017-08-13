import Command
import Console
import Foundation
import Service

public final class ProviderInstall: Command {
    public let signature: CommandSignature
    public let providers: [Provider]
    public let publicDir: String
    public let viewsDir: String
    
    public init(
        providers: [Provider],
        publicDir: String,
        viewsDir: String
    ) {
        self.signature = .init(arguments: [], options: [], help: ["Installs Resources and Public files from providers"])
        self.providers = providers
        self.publicDir = publicDir
        self.viewsDir = viewsDir
    }

    public func run(using console: Console, with input: CommandInput) throws {
        try console.print("This command copies resource files from your providers")
        try console.print("into your root project directories.")
        try console.warning("Any files with the same name will be replaced.")
        try console.print("You have \(providers.count) providers that will be installed.")
        guard try console.confirm("Would you like to continue?") else {
            try console.warning("Install cancelled.")
            return
        }
        
        for (i, provider) in providers.enumerated() {
            let type = Swift.type(of: provider)
            try console.info("[\(i + 1)/\(providers.count)]", newLine: false)
            try console.print(" Installing \(type.repositoryName)")
            
            guard let root = type.providedDirectory else {
                try console.error("Could not find directory for \(type)")
                continue
            }
            
            let publicDir = root + type.publicDir.finished(with: "/")
            let viewsDir = root + type.viewsDir.finished(with: "/")
            
            var dirty = false
            
            do {
                _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "cp -rf \(publicDir)* \(self.publicDir)"]) as Data
                try console.print("Copied public files")
                dirty = true
            } catch {
                //
            }
            
            do {
                _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "cp -rf \(viewsDir)* \(self.viewsDir)"]) as Data
                try console.print("Copied resource files")
                dirty = true
            } catch {
                //
            }
            
            if dirty {
                try console.success("Installed \(type.repositoryName)")
            } else {
                try console.print("Nothing to install")
            }
        }
    }
}

// MARK: Service

extension ProviderInstall: ServiceType {
    /// See Service.serviceName
    public static var serviceName: String {
        return "provider-install"
    }

    /// See Service.serviceSupports
    public static var serviceSupports: [Any.Type] {
        return [Command.self]
    }

    public static func makeService(for container: Container) throws -> ProviderInstall? {
        let dirs = WorkingDirectory()
        return ProviderInstall(
            providers: container.services.providers,
            publicDir: dirs.publicDir,
            viewsDir: dirs.viewsDir
        )
    }
}
