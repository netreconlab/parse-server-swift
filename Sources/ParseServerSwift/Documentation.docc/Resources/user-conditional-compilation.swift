#if canImport(Vapor)
import Vapor
typealias UserBase = ParseCloudUser
#else
typealias UserBase = ParseUser
#endif

struct User: UserBase {
    // ... properties
}
