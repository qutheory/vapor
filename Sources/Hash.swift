#if os(Linux)
    import Glibc
#endif

import Foundation
import CryptoSwift


public class Hash {
    
    /**
     * The `applicationKey` adds an additional layer
     * of security to all hashes. 
     * 
     * Ensure this key stays
     * the same during the lifetime of your application, since
     * changing it will result in mismatching hashes.
     */
    public static var applicationKey: String = ""

    /**
     * Any class that conforms to the `HashDriver` 
     * protocol may be set as the `Hash`'s driver.
     * It will be used to create the hashes 
     * request by functions like `make()`
     */
    public static var driver: HashDriver = CryptoHasher()
    
    /**
     * Hashes a string using the `Hash` class's 
     * current `HashDriver` and `applicationString` salt.
	 *
	 * - returns: Hashed string
     */
    public class func make(string: String) -> String {
        return Hash.driver.hash(string, key: applicationKey)
    }
    
}

/**
 * Classes that conform to `HashDriver` may be set
 * as the `Hash` classes hashing engine.
 */
public protocol HashDriver {

	/**
	 * Given a string, this function will 
	 * return the hashed string according
	 * to whatever algorithm it chooses to implement.
	 */
	func hash(message: String, key: String) -> String
}


public class CryptoHasher: HashDriver {

    public func hash(message: String, key: String) -> String {
    
        var msgBuff = [UInt8]()
        msgBuff += message.utf8
        
        var keyBuff = [UInt8]()
        keyBuff += key.utf8
        
        do {
            let hmac = try Authenticator.HMAC(key: keyBuff, variant: .sha256).authenticate(msgBuff)
            return NSData.withBytes(hmac).toHexString()
        } catch {
            Log.error("Unable to create hash, returning hash for empty string.")
            return "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        }

    }
    
}