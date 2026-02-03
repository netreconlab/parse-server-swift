// Custom error with unique code
let customError = ParseError(otherCode: 1001,
                            message: "My custom error message")
return ParseHookResponse<String>(error: customError)
