// Swift client code
do {
    let response: String = try await Cloud.runFunction(name: "hello")
    print("Response: \(response)") // "Hello world!"
} catch {
    print("Error calling function: \(error)")
}
