var object = parseRequest.object!

// Add a timestamp or modify data
// Note: Only modify if you have a mutable copy

req.logger.info("Before save is being made: \(object)")
return ParseHookResponse(success: object)
