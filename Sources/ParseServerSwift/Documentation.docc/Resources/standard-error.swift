// Standard Parse error
let error = ParseError(code: .invalidSessionToken,
                       message: "User must be signed in")
return ParseHookResponse<String>(error: error)
