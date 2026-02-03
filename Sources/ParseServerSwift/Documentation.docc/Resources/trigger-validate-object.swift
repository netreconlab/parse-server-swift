guard let object = parseRequest.object else {
    return ParseHookResponse(error: .init(code: .missingObjectId,
                                          message: "Object not sent in request."))
}

// Validate points are within acceptable range
if let points = object.points, points < 0 {
    let error = ParseError(code: .validationError,
                           message: "Points cannot be negative")
    return ParseHookResponse<GameScore>(error: error)
}

// Allow the save
return ParseHookResponse(success: object)
