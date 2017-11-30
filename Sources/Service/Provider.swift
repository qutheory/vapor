/// Providers allow external projects to be easily
/// integrated into an application's service container.
///
/// Simply add the provider using services.register(Provider.self)
///
///The Provider should take care of setting up any
///necessary configurations on itself and the container.
public protocol Provider {
    /// This should be the name of the actual repository
    /// that contains the Provider.
    /// 
    /// this will be used for things like providing 
    /// resources
    ///
    /// this will default to stripped camel casing, 
    /// for example MyProvider will become `my-provider`
    /// if your Provider is providing resources
    /// it is HIGHLY recommended to provide a static let
    /// for performance considerations
    static var repositoryName: String { get }
    
    /// The location of the public directory
    /// _relative_ to the root of the provider package.
    static var publicDir: String { get }
    
    /// The location of the views directory
    /// _relative_ to the root of the provider package.
    static var viewsDir: String { get }
    
    /// Register all services provided by the provider here.
    func register(_ services: inout Services) throws

    /// Called after the container has initialized.
    func boot(_ context: Context) throws
}

// MARK: Optional

extension Provider {
    public static var publicDir: String {
        return "Public"
    }
    
    public static var viewsDir: String {
        return "Resources/Views"
    }
}
