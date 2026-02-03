// Get Parse Server version
guard let version = try await ParseServer.information().version else {
    let error = ParseError(code: .otherCause,
                           message: "Could not retrieve server information")
    return ParseHookResponse<String>(error: error)
}
return ParseHookResponse(success: "\(version)")
