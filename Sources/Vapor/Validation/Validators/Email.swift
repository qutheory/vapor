extension Validator where T == String {

    /// Validates whether a `String` is a valid email address.
    public static var email: Validator<T> {
        Email(isInverted: false).validator()
    }
}

extension Validator {

    /// `ValidatorResult` of a validator that validates whether a `String` is a valid email address.
    public struct EmailValidatorResult: ValidatorResult {

        /// The `failed` state is inverted.
        public let isInverted: Bool

        /// The input is a valid email address
        public let isValidEmail: Bool

        /// See `CustomStringConvertible`.
        public var description: String { "is \(isValidEmail ? "" : "not ")a valid email address" }

        /// See `ValidatorResult`.
        public var failed: Bool { isValidEmail == isInverted }
    }

    struct Email: ValidatorType {
        let isInverted: Bool

        func inverted() -> Email {
            .init(isInverted: !isInverted)
        }

        func validate(_ string: String) -> EmailValidatorResult {
            guard
                let range = string.range(of: regex, options: [.regularExpression]),
                range.lowerBound == string.startIndex && range.upperBound == string.endIndex,
                // FIXME: these numbers are incorrect and too restrictive
                string.count <= 80, // total length
                string.split(separator: "@")[0].count <= 64 // length before `@`
            else {
                return .init(isInverted: isInverted, isValidEmail: false)
            }
            return .init(isInverted: isInverted, isValidEmail: true)
        }
    }
}

// FIXME: this regex is too strict with capitalization of the domain part
private let regex: String = """
(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}\
~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\\
x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-\
z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5\
]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-\
9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\
-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])
"""