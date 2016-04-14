public protocol RequestContentSubscript {}

extension String: RequestContentSubscript { }
extension Int: RequestContentSubscript {}

public struct KeyedNode {
    var key: String
    var node: Node?
}

public extension Request {

    /**
        The data received from the request in json body or url query
    */
    public struct Content {
        // MARK: Initialization
        public let query: [String: String]
        public let json: Json?
        public let formEncoded: [String: String]?

        internal init(query: [String: String], json: Json?, formEncoded: [String: String]?) {
            self.query = query
            self.json = json
            self.formEncoded = formEncoded
        }

        // MARK: Subscripting
        public subscript(index: Int) -> Node? {
            if let value = query["\(index)"] {
                return value
            } else if let value = json?.array?[index] {
                return value
            } else if let value = formEncoded?["\(index)"] {
                return value
            } else {
                return nil
            }
        }

        public subscript(key: String) -> Node? {
            if let value = query[key] {
                return value
            } else if let value = json?.object?[key] {
                return value
            } else if let value = formEncoded?[key] {
                return value
            } else {
                return nil
            }
        }

        public subscript(key: String) -> KeyedNode {
            return KeyedNode(key: key, node: self[key])
        }
    }

}

extension String: Node {
    public var isNull: Bool {
        return self == "null"
    }

    public var bool: Bool? {
        return Bool(self)
    }

    public var int: Int? {
        guard let double = double else { return nil }
        return Int(double)
    }

    public var uint: UInt? {
        guard let double = double else { return nil }
        return UInt(double)
    }

    public var float: Float? {
        guard let double = double else { return nil }
        return Float(double)
    }

    public var double: Double? {
        return Double(self)
    }

    public var string: String? {
        return self
    }

    public var array: [Node]? {
        return self
            .split(",")
            .map { $0 as Node }
    }

    public var object: [String : Node]? {
        return nil
    }

    public var json: Json? {
        return Json(self)
    }
}


extension String {

    /**
        Query data is information appended to the URL path
        as `key=value` pairs separated by `&` after
        an initial `?`

        - returns: String dictionary of parsed Query data
     */
    internal func queryData() -> [String: String] {
        // First `?` indicates query, subsequent `?` should be included as part of the arguments
        return split("?", maxSplits: 1)
            .dropFirst()
            .reduce("", combine: +)
            .keyValuePairs()
    }

    /**
        Parses `key=value` pair data separated by `&`.

        - returns: String dictionary of parsed data
     */
    internal func keyValuePairs() -> [String: String] {
        var data: [String: String] = [:]

        for pair in self.split("&") {
            let tokens = pair.split("=", maxSplits: 1)

            if
                let name = tokens.first,
                let value = tokens.last,
                let parsedName = try? String(percentEncoded: name) {
                data[parsedName] = try? String(percentEncoded: value)
            }
        }

        return data
    }

}

extension Bool {
    /**
        This function seeks to replicate the expected behavior of `var boolValue: Bool` on `NSString`.  Any variant of `yes`, `y`, `true`, `t`, or any numerical value greater than 0 will be considered `true`
    */
    public init(_ string: String) {
        let cleaned = string
            .lowercased()
            .characters
            .first ?? "n"

        switch cleaned {
        case "t", "y", "1":
            self = true
        default:
            if let int = Int(String(cleaned)) where int > 0 {
                self = true
            } else {
                self = false
            }

        }
    }
}
