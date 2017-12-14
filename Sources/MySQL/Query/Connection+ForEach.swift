import Async
import JunkDrawer

extension MySQLConnection {
    /// A simple callback closure
    public typealias Callback<T> = (T) throws -> ()

    /// Loops over all rows resulting from the query
    ///
    /// - parameter query: Fetches results using this query
    /// - parameter handler: Executes the handler for each `Row`
    /// - throws: Network error
    /// - returns: A future that will be completed when all results have been processed by the handler
    @discardableResult
    internal func forEachRow(in query: MySQLQuery, _ handler: @escaping Callback<Row>) -> Signal {
        let promise = Promise(Void.self)

        let rowStream = RowStream(mysql41: self.mysql41)
        packetStream.stream(to: rowStream)
            .drain(onInput: handler)
            .catch(onError: promise.fail)
            .finally(onClose: { promise.complete() })
        
        // Send the query
        do {
            try self.write(query: query.queryString)
        } catch {
            promise.fail(error)
        }
        
        return promise.future
    }
    
    /// Loops over all rows resulting from the query
    ///
    /// - parameter type: Deserializes all rows to the provided `Decodable` `D`
    /// - parameter query: Fetches results using this query
    /// - parameter handler: Executes the handler for each deserialized result of type `D`
    /// - throws: Network error
    /// - returns: A future that will be completed when all results have been processed by the handler
    @discardableResult
    public func forEach<D>(_ type: D.Type, in query: MySQLQuery, _ handler: @escaping Callback<D>) -> Signal
        where D: Decodable
    {
        return forEachRow(in: query) { row in
            let decoder = try RowDecoder(keyed: row, lossyIntegers: true, lossyStrings: true)
            let d = try D(from: decoder)
            
            try handler(d)
        }
    }
}
