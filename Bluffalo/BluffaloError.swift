import Foundation

enum BluffaloError: Error {
    case sourceKittenNotFound(path: String)
    case sourceKittenParseFailure
}
