import Async
import MySQL

/// A MySQL logger.
public protocol MySQLLogger {
    /// Log the query.
    func log(query: MySQLQuery) -> Signal
}

extension DatabaseLogger: MySQLLogger {
    /// See MySQLLogger.log
    public func log(query: MySQLQuery) -> Signal {
        let log = DatabaseLog(query: query.queryString)
        return record(log: log)
    }
}
