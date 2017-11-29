extension Payload {
    /// Decodes an HTTP/2 integer
    ///
    /// http://httpwg.org/specs/rfc7541.html#rfc.section.5.1
    func parseInteger(prefix n: Int) throws -> Int {
        guard n >= 1 && n <= 8, bytePosition < data.count else {
            throw HTTP2Error(.invalidPrefixSize(n))
        }
        
        let max: UInt8 = numericCast(power(of: 2, to: n) - 1)
        var byte: UInt8 = data[bytePosition] & max
        
        bytePosition += 1
        
        if byte < max {
            return numericCast(byte)
        }
        
        var integer: Int = numericCast(byte)
        var offset = 0
        var iterations = 0
        
        repeat {
            byte = data[bytePosition]
            bytePosition += 1
            integer += numericCast(byte & 0b01111111) * power(of: 2, to: offset)
            offset = offset &+ 7
            iterations = iterations &+ 1
            // While the significant bit is set, prevent too many iterations
        } while byte & 0b10000000 == 0b10000000 && iterations < 3
        
        return integer
    }
    
    /// http://httpwg.org/specs/rfc7541.html#rfc.section.5.1
    func append(integer int: Int, prefix n: Int) throws {
        guard n >= 1 && n <= 8 else {
            throw HTTP2Error(.invalidPrefixSize(n))
        }
        
        let max: UInt8 = numericCast(power(of: 2, to: n) - 1)
        
        guard int >= numericCast(max) else {
            data.append(numericCast(int))
            return
        }
        
        data.append(max)
        appendLongInteger(int, n: n)
    }
    
    /// http://httpwg.org/specs/rfc7541.html#rfc.section.5.1
    func serialize(integer int: Int, prefix n: Int) throws {
        guard n >= 1 && n <= 8, bytePosition < data.count else {
            throw HTTP2Error(.invalidPrefixSize(n))
        }
        
        let max: UInt8 = numericCast(power(of: 2, to: n) - 1)
        
        guard int >= numericCast(max) else {
            data[data.count - 1] |= numericCast(int)
            return
        }
        
        data.append(max)
        appendLongInteger(int, n: n)
    }
    
    /// http://httpwg.org/specs/rfc7541.html#rfc.section.5.1
    fileprivate func appendLongInteger(_ int: Int, n: Int) {
        var int = int - (power(of: 2, to: n) - 1)
        
        while int >= 128 {
            data.append(numericCast(int % 128 + 128))
            int = int / 128
        }
        
        data.append(numericCast(int))
    }
}

fileprivate func power(of base: Int, to times: Int) -> Int {
    var amount = base
    
    if times == 0 {
        return 1
    }
    
    for _ in 0..<times - 1 {
        amount = amount &* base
    }
    
    return amount
}
