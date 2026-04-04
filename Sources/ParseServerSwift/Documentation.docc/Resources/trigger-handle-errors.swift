guard let object = parseRequest.object else {
    return ParseHookResponse(error: .init(code: .missingObjectId,
                                          message: "Object not sent in request."))
}
