import Foundation
import SwiftUI

public protocol Tweakable: Equatable {}

extension Int: Tweakable {}
extension Double: Tweakable {}
extension String: Tweakable {}
extension Bool: Tweakable {}
extension Color: Tweakable {}
extension Optional: Tweakable where Wrapped: Tweakable {}
extension Array: Tweakable where Element: Tweakable {}

public struct SectionModel<Element> {
    public var name: String
    public var elements: [Element]

    public init(name: String, elements: [Element]) {
        self.name = name
        self.elements = elements
    }
}
