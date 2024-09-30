import Foundation

@objc public class BrotherPrint: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
