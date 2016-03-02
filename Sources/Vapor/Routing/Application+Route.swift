//
//  Application+Route.swift
//  Vapor
//
//  Created by Tanner Nelson on 2/23/16.
//  Copyright © 2016 Tanner Nelson. All rights reserved.
//

import Foundation

extension Application {
    
    public final func get(path: String, handler: Route.Handler) {
        self.add(.Get, path: path, handler: handler)
    }
    
    public final func post(path: String, handler: Route.Handler) {
        self.add(.Post, path: path, handler: handler)
    }
    
    public final func put(path: String, handler: Route.Handler) {
        self.add(.Put, path: path, handler: handler)
    }
    
    public final func patch(path: String, handler: Route.Handler) {
        self.add(.Patch, path: path, handler: handler)
    }
    
    public final func delete(path: String, handler: Route.Handler) {
        self.add(.Delete, path: path, handler: handler)
    }
    
    public final func options(path: String, handler: Route.Handler) {
        self.add(.Options, path: path, handler: handler)
    }
    
    public final func any(path: String, handler: Route.Handler) {
        self.get(path, handler: handler)
        self.post(path, handler: handler)
        self.put(path, handler: handler)
        self.patch(path, handler: handler)
        self.delete(path, handler: handler)
    }
    

    
    /**
        Creates standard Create, Read, Update, Delete routes
        using the Handlers from a supplied `Controller`.
     
        The `path` supports nested resources, like `users.photos`.
        users/:user_id/photos/:id
     
        Note: You are responsible for pluralizing your endpoints.
    */
    public final func resource<RoutedController: ResourceController>(path: String, controller: RoutedController.Type) {
        let last = "/:id"
        let shortPath = path.componentsSeparatedByString(".")
            .flatMap { component in
                return [component, "/:\(component)_id/"]
            }
            .dropLast()
            .joinWithSeparator("")
        let fullPath = shortPath + last

        // ie: /users
        self.add(.Get, path: shortPath, action: RoutedController.index)
        self.add(.Post, path: shortPath, action: RoutedController.store)

        // ie: /users/:id
        self.add(.Get, path: fullPath, action: RoutedController.show)
        self.add(.Put, path: fullPath, action: RoutedController.update)
        self.add(.Delete, path: fullPath, action: RoutedController.destroy)
    }

    public final func add<RoutedController: Controller>(method: Request.Method, path: String, action: (RoutedController) -> (Request) throws -> ResponseConvertible) {
        add(method, path: path) { request in
            let controller = RoutedController()
            let actionCall = action(controller)
            return try actionCall(request).response()
        }
    }
    
    public final func add(method: Request.Method, path: String, handler: Route.Handler) {
        
        //Convert Route.Handler to Request.Handler
        var handler = { request in
            return try handler(request).response()
        }
        
        //Apply any scoped middlewares
        for middleware in scopedMiddleware {
            handler = middleware.handle(handler)
        }
        
        //Store the route for registering with Router later
        let host = scopedHost ?? "*"
        
        //Apply any scoped prefix
        var path = path
        if let prefix = scopedPrefix {
            path = prefix + "/" + path
        }
        
        let route = Route(host: host, method: method, path: path, handler: handler)
        self.routes.append(route)
    }
    
    /**
        Applies the middleware to the routes defined
        inside the closure. This method can be nested within
        itself safely.
    */
    public final func middleware(middleware: Middleware.Type, handler: () -> ()) {
       self.middleware([middleware], handler: handler)
    }
    
    public final func middleware(middleware: [Middleware.Type], handler: () -> ()) {
        let original = scopedMiddleware
        scopedMiddleware += middleware
        
        handler()
        
        scopedMiddleware = original
    }
    
    public final func host(host: String, handler: () -> Void) {
        let original = scopedHost
        scopedHost = host
        
        handler()
        
        scopedHost = original
    }
    
    /**
        Create multiple routes with the same base URL
        without repeating yourself.
    */
    public func group(prefix: String, @noescape handler: () -> Void) {
        let original = scopedPrefix
        
        //append original with a trailing slash
        if let original = original {
            scopedPrefix = original + "/" + prefix
        } else {
            scopedPrefix = prefix
        }
        
        handler()
        
        scopedPrefix = original
    }
}