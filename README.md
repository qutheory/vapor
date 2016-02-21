![Vapor](https://cloud.githubusercontent.com/assets/1342803/12457900/1825c70c-bf75-11e5-9080-989345fa43e2.png)

# Vapor

A Laravel/Lumen Inspired Web Framework for Swift that works on iOS, OS X, and Ubuntu.

- [x] Insanely fast
- [x] Beautiful syntax
- [x] Type safe

## Badges

[![Build Status](https://img.shields.io/travis/tannernelson/vapor.svg?style=flat-square)](https://travis-ci.org/tannernelson/vapor)
[![Issue Stats](http://issuestats.com/github/tannernelson/vapor/badge/pr?style=flat-square)](http://issuestats.com/github/tannernelson/vapor)
[![PRs Welcome](https://img.shields.io/badge/prs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
[![Slack Status](http://slack.tanner.xyz:8085/badge.svg?style=flat-square)](http://slack.tanner.xyz:8085)

## Getting Started

Clone the [Example](https://github.com/tannernelson/vapor-example) project to start making your application or check out the [live demo](http://vapor.tanner.xyz:8080) running on Ubuntu. This repository is for the framework module.

You can also download the alpha [Vapor Installer](https://github.com/mpclarkson/vapor-installer), which allows you to create a new project at the command line e.g. `vapor new MyProject`

You must have Swift 2.2 or later installed. You can learn more about Swift 2.2 at [Swift.org](http://swift.org)

Want to make a pull request? You can learn how from this *free* series [How to Contribute to an Open Source Project on GitHub](https://egghead.io/series/how-to-contribute-to-an-open-source-project-on-github)

### Work in Progress

This is a work in progress, so don't rely on this for anything important. And pull requests are welcome!

## Wiki

Visit the [Vapor Wiki](https://github.com/tannernelson/vapor/wiki) for extensive documentation on using and contributing to Vapor.

## Server

Starting the server takes two lines.

`main.swift`
```swift
import Vapor

let server = Server()
server.run()
```

You can also choose which port the server runs on.

```swift
server.run(port: 8080)
```

If you are having trouble connecting, make sure your ports are open. Check out `apt-get ufw` for simple port management.

## Routing

Routing in Vapor is simple and very similar to Laravel.

`main.swift`
```swift
Route.get("welcome") { request in
	return "Hello"
}

//...start server
```

Here we will respond to all requests to `http://example.com/welcome` with the string `"Hello"`.

### JSON

Responding with JSON is easy.

```swift
Route.get("version") { request in
	return ["version": "1.0"]
}
```

This responds to all requests to `http://example.com/version` with the JSON dictionary `{"version": "1.0"}` and `Content-Type: application/json`.

### Views

You can also respond with HTML pages.

```swift
Route.get("/") { request in
	return View(path: "index.html")
}
```

Or [Stencil](https://github.com/kylef/Stencil) templates.

`index.stencil`

```mustache
<html>
	<h1>{{ message }}</h1>
</html>
```

```swift
Route.get("/") { request in
	return View(path: "index.stencil", context: ["message": "Hello"])
}
```

If you have `VaporStencil` added, just put the View file in the `Resources` folder at the root of your project and it will be served.

#### Stencil

To add `VaporStencil`, add the following package to your `Package.swift`.

`Package.swift`
```swift
.Package(url: "https://github.com/tannernelson/vapor-stencil.git", majorVersion: 0)
```

Then set the `StencilRenderer()` on your `View.renderers` for whatever file extensions you would like to be rendered as `Stencil` templates.

`main.swift`
```swift
import VaporStencil

//set the stencil renderer
//for all .stencil files
View.renderers[".stencil"] = StencilRenderer()
```

### Response

A manual response can be returned if you want to set something like `cookies`.

```swift
Route.get("cookie") { request in
	let response = Response(status: .OK, text: "Cookie was set")
	response.cookies["test"] = "123"
	return response
}
```

The Status enum above (`.OK`) can be one of the following.

```swift
public enum Status {
    case OK, Created, Accepted
    case MovedPermanently
    case BadRequest, Unauthorized, Forbidden, NotFound
    case ServerError
    case Unknown
    case Custom(Int)
}
```

Or something custom.

```swift
let status: Status = .Custom(420) //https://dev.twitter.com/overview/api/response-codes
```

### Public

All files put in the `Public` folder at the root of your project will be available at the root of your domain. This is a great place to put your assets (`.css`, `.js`, `.png`, etc).

## Request

Every route call gets passed a `Request` object. This can be used to grab query and path parameters.

This is a list of the properties available on the request object.

```swift
let method: Method
var parameters: [String: String] //URL parameters like id in user/:id
var data: [String: String] //GET or POST data
var cookies: [String: String]
var session: Session
```

### Session

Sessions will be kept track of using the `vapor-session` cookie. The default (and currently only) session driver is `.Memory`.

```swift
if let name = request.session.data["name"] {
	//name was in session
}

//store name in session
request.session.data["name"] = "Vapor"
```

## Database

Vapor was designed alongside [Fluent](https://github.com/tannernelson/fluent), an Eloquent inspired ORM that empowers simple and expressive database management.

```swift
import Fluent

if let user = User.find(5) {
    print("Found \(user.name)")

    user.name = "New Name"
    user.save()
}
```

Underlying [Fluent](https://github.com/tannernelson/fluent) is a powerful Query builder.

```swift
let user = Query<User>().filter("id", notIn: [1, 2, 3]).filter("age", .GreaterThan, 21).first
```

## Controllers

Controllers are great for keeping your code organized. `Route` directives can take whole controllers or controller methods as arguments instead of closures.

`main.swift`
```swift
Route.get("heartbeat", closure: HeartbeatController().index)
```

To pass a function name as a closure like above, the closure must have the function signature

```swift
func index(request: Request) -> ResponseConvertible
```

Here is an example of a controller for returning an API heartbeat.

`HearbeatController.swift`
```swift
import Vapor

class HeartbeatController: Controller {

	override func index(request: Request) -> AnyObject {
		return ["lub": "dub"]
	}

}
```

Here the `HeartbeatControllers`'s index method will be called when `http://example.com/heartbeat/alternate` is visited.

### Resource Controllers

Resource controllers take advantage of CRUD-like `index`, `show`, `store`, `update`, `destroy` methods to make setting up REST APIs easy.

### Single Resources

```swift
Route.resource("user", controller: UserController())
```

This will create the appropriate `GET`, `POST`, `DELETE`, etc methods for individual and groups of users:

- .Get /user - an index of users
- .Get /user/:id - a single user etc

### Nested Resources

You can also create nested resources for one to many relationships. For example, a "company" can have multiple "users".
This can be achieved by using dot notation in the path, as follows:

```swift
Route.resource("company.user", controller: CompanyUserController())
```

This will create appropriate nested `GET`, `POST`, `DELETE`, etc methods, for example:

- .Get /company/:company_id/user - an index of users at a specific company
- .Get /company/:company_id/user/:id - a specific user at a specific company

You can now access these parameters in a controller, as follows:

```swift
let companyId = request.parameters["company_id"]
let userId = request.parameters["id"] //Note: The final parameter is always `id`.
```

## Middleware

Create a class conforming to `Middleware` to hook into server requests and responses. Append your classes to the `server.middleware` array in the order you want them to run..

```swift
class MyMiddleware: Middleware {
    func handle(handler: Request -> Response) -> (Request -> Response) {
        return { request in
            print("Incoming request from \(request.address)")

            let response = handler(request)

            print("Responding with status \(response.status)")

            return response
        }
    }
}

server.middleware.append(MyMiddleware())
```

## Async

Use the `AsyncResponse` to send custom, asynchronous responses. You have full control over the response here, meaning you are responsible for writing all required headers and releasing the `Socket` when done. (Thanks @elliottminns)

```swift
Route.get("async") { request in
	return AsyncResponse() { socket in
		try socket.writeUTF8("HTTP/1.1 200 OK\r\n")
		try socket.writeUTF8("Content-Type: application/json\r\n\r\n")
		try socket.writeUTF8("{\"hello\": \"world\"}")

		socket.release()
	}
}
```

## Hash

Vapor currently supports `SHA1` hashes.

```swift
let hello = Hash.make("world")
```

For added security, set a custom `applicationKey` on the `Hash` class.

```swift
Hash.applicationKey = "my-secret-key"
```

## Deploying

Vapor has been successfully tested on Ubuntu 14.04 LTS (DigitalOcean) and Ubuntu 15.10 (VirtualBox).

### DigitalOcean

To deploy to DigitalOcean, simply

- Install Swift 2.2
	- `wget` the .tar.gz from Apple
	- Set the `export PATH` in your `~/.bashrc`
	- (you may need to install `binutils` as well if you see `ar not found`)
- Clone your fork of the `vapor-example` repository to the server
- `cd` into the repository
	- Run `swift build`
	- Run `.build/debug/MyApp`
	- (you may need to run as `sudo` to use certain ports)
	- (you may need to install `ufw` to set appropriate ports)

#### Upstart

To start your `Vapor` site automatically when the server is booted, add this file to your server.

`/etc/init/vapor-example.conf`

```conf
description "Vapor Example"

start on startup

exec /home/<user_name>/vapor-example/.build/release/VaporApp --workDir=/home/<user_name>/vapor-example
```

You additionally have access to the following commands for starting and stopping your server.

```shell
sudo stop vapor-example
sudo start vapor-example
```

The following script is useful for upgrading your website.

```shell
git pull
swift build --configuration release
sudo stop vapor-example
sudo start vapor-example
```

### Heroku

To deploy on Heroku, one can use [Kyle Fuller's Heroku buildpack](https://github.com/kylef/heroku-buildpack-swift) which works out of the box with the `vapor-example`.

My website `http://tanner.xyz` is currently running using Vapor.

## Attributions

This project is based on [Swifter](https://github.com/glock45/swifter) by Damian Kołakowski. It uses compatibility code from [NSLinux](https://github.com/johnno1962/NSLinux) by johnno1962.

Go checkout and star their repos.
