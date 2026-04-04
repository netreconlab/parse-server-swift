// Swift client code with parameters
struct FooParameters: Codable {
    var foo: String?
    var bar: Int?
}

let params = FooParameters(foo: "test", bar: 42)
let response: String = try await Cloud.runFunction(name: "hello", 
                                                   params: params)
