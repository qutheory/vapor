//
//  Process.swift
//  Vapor
//
//  Created by Logan Wright on 2/27/16.
//  Copyright © 2016 Tanner Nelson. All rights reserved.
//

extension Process {

    /**
     Returns the string value of an
     argument passed to the executable
     in the format --name=value

     - parameter argument: the name of the argument to get the value for
     - parameter arguments: arguments to search within.  Primarily used for testing through injection

     - returns: the value matching the argument if possible
     */
    public static func valueFor(argument name: String, inArguments arguments: [String] = Process.arguments) -> String? {
        //FIXME
        #if swift(>=3.0)
        for argument in arguments where argument.hasPrefix("--\(name)=") {
            return argument.split("=").last
        }
        #endif
        return nil
    }

}
