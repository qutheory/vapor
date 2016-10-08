extension Node {
    /**
         Anywhere we find a key or value that is a string w/ a leading `$`,
         we will look for it in environment, or treat as `nil`.
         
         If there is a `:`, all content following colon will be treated as fallback.
         
         For example:
         
             ["port": "$PORT:8080"]
         
         If `PORT` has value, the node will be `["port": "<value of port>"]
         If `PORT` has NO value, the node will be `["port": "8080"]`
         
         Another example: 
         
            ["key": "$MY_KEY"]

         If `MY_KEY` has value, the node will be `["key": "<value of key>"]
         If `PORT` has NO value, the node will be nil
    */
    internal func hydratedEnv() -> Node? {
        switch self {
        case .null, .number(_), .bool(_), .bytes(_), .date(_):
            return self
        case let .object(ob):
            guard !ob.isEmpty else { return self }

            var mapped = [String: Node]()
            ob.forEach { k, v in
                guard let k = k.hydratedEnv(), let v = v.hydratedEnv() else { return }
                mapped[k] = v
            }
            guard !mapped.isEmpty else { return nil }
            return .object(mapped)
        case let .array(arr):
            let mapped = arr.flatMap { $0.hydratedEnv() }
            return .array(mapped)
        case let .string(str):
            return str.hydratedEnv().flatMap(Node.string)
        }
    }
}
