import Async

public final class Contains: LeafTag {
    public init() {}

    public func render(parsed: ParsedTag, context: inout LeafData, renderer: LeafRenderer) throws -> Future<LeafData?> {
        let promise = Promise(LeafData?.self)

        try parsed.requireParameterCount(2)

        if let array = parsed.parameters[0].array {
            let compare = parsed.parameters[1]
            promise.complete(.bool(array.contains(compare)))
        } else {
            promise.complete(.bool(false))
        }

        return promise.future
    }
}
