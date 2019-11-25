import NIO

public protocol Provider: class {
    var application: Application { get }
    init(_ application: Application)
    func willBoot() throws
    func didBoot() throws
    func shutdown()
}

extension Provider {
    public func willBoot() throws { }
    public func didBoot() throws { }
    public func shutdown() { }
}

public final class Providers {
    private var lookup: [ObjectIdentifier: Provider]
    private var all: [Provider]
    private var didShutdown: Bool
    
    public func clear() {
        self.lookup = [:]
        self.all = []
    }
    
    init() {
        self.lookup = [:]
        self.all = []
        self.didShutdown = false
    }
    
    func add<T>(_ provider: T)
        where T: Provider
    {
        self.lookup[ObjectIdentifier(T.self)] = provider
        self.all.append(provider)
    }
    
    public func require<T>(
        _ type: T.Type,
        file: StaticString = #file,
        line: UInt = #line
    ) -> T
        where T: Provider
    {
        guard let provider = self.get(T.self) else {
            fatalError("No service provider \(T.self) registered. Consider registering with app.use(\(T.self).self)", file: file, line: line)
        }
        return provider
    }
    
    public func get<T>(_ type: T.Type) -> T?
        where T: Provider
    {
        self.lookup[ObjectIdentifier(T.self)] as? T
    }
    
    func boot() throws {
        try self.all.forEach { try $0.willBoot() }
        try self.all.forEach { try $0.didBoot() }
    }
    
    func shutdown() {
        self.didShutdown = true
        self.all.reversed().forEach { $0.shutdown() }
        self.clear()
    }
    
    deinit {
        assert(self.didShutdown, "Providers did not shutdown before deinit")
    }
}
