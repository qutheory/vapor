extension Validator {

    /// Validates that all characters in a `String` are ASCII (bytes 0..<128).
    public static var ascii: Validator<String> {
        .characterSet(.ascii)
    }

    /// Validates that all characters in a `String` are alphanumeric (a-z,A-Z,0-9).
    public static var alphanumeric: Validator<String> {
        .characterSet(.alphanumerics)
    }

    /// Validates that all characters in a `String` are in the supplied `CharacterSet`.
    public static func characterSet(_ characterSet: Foundation.CharacterSet) -> Validator<String> {
        CharacterSet(characterSet: characterSet).validator()
    }

    /// `ValidatorResult` of a validator that validates that a `String` contains characters in a given `CharacterSet`.
    public struct CharacterSetValidatorResult: ValidatorResult {

        /// The set of characters the input may contain.
        public let characterSet: Foundation.CharacterSet

        /// On validation failure, the first substring of the input with characters not contained in `characterSet`.
        public let invalidSlice: Substring?

        /// See `CustomStringConvertible`.
        public var description: String {
            var string: String
            if let invalidSlice = invalidSlice {
                string = "contains an invalid character: '\(invalidSlice)'"
            } else {
                string = "contains valid characters"
            }
            if !characterSet.traits.isEmpty {
                string += " (allowed: \(characterSet.traits.joined(separator: ", ")))"
            }
            return string
        }

        /// See `ValidatorResult`.
        public var failed: Bool { invalidSlice != nil }
    }

    struct CharacterSet: ValidatorType {
        let characterSet: Foundation.CharacterSet

        func validate(_ s: String) -> CharacterSetValidatorResult {
            .init(
                characterSet: characterSet,
                invalidSlice: s.rangeOfCharacter(from: characterSet.inverted).map { s[$0] }
            )
        }
    }
}

/// Unions two character sets.
///
///     .characterSet(.alphanumerics + .whitespaces)
///
public func +(lhs: CharacterSet, rhs: CharacterSet) -> CharacterSet {
    lhs.union(rhs)
}

private extension Foundation.CharacterSet {

    /// ASCII (byte 0..<128) character set.
    static var ascii: CharacterSet {
        .init((0..<128).map(Unicode.Scalar.init))
    }

    /// Returns an array of strings describing the contents of this `CharacterSet`.
    var traits: [String] {
        var desc: [String] = []
        if isSuperset(of: .newlines) {
            desc.append("newlines")
        }
        if isSuperset(of: .whitespaces) {
            desc.append("whitespace")
        }
        if isSuperset(of: .capitalizedLetters) {
            desc.append("A-Z")
        }
        if isSuperset(of: .lowercaseLetters) {
            desc.append("a-z")
        }
        if isSuperset(of: .decimalDigits) {
            desc.append("0-9")
        }
        return desc
    }
}
