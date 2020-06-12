import Foundation
import SwiftUI

public struct ValueTransformer<Source, Destination> {
    public let transform: (Source) -> Destination
    public let retrieve: (Destination) -> Source?
}

public protocol Tweakable: Equatable {
    static var valueTransformer: ValueTransformer<Self, String> { get }
}

extension Tweakable {
    public var stringRepresentation: String {
        Self.valueTransformer.transform(self)
    }
    public init?(stringRepresentation: String) {
        guard let value = Self.valueTransformer.retrieve(stringRepresentation) else { return nil }
        self = value
    }
    public func defaultPreviewView() -> some View {
        Text(stringRepresentation)
    }
}

extension Tweakable where Self: LosslessStringConvertible {
    public static var valueTransformer: ValueTransformer<Self, String> {
        ValueTransformer(transform: { $0.description }, retrieve: { Self($0) })
    }
}

extension Tweakable where Self: RawRepresentable, RawValue: Tweakable {
    public static var valueTransformer: ValueTransformer<Self, String> {
        ValueTransformer(transform: { $0.rawValue.stringRepresentation },
                         retrieve: {
            guard let value = RawValue(stringRepresentation: $0) else { return nil }
            return Self(rawValue: value)
        })
    }
}

extension Int: Tweakable {}
extension Double: Tweakable {}
extension String: Tweakable {}
extension Bool: Tweakable {}

extension Array: Tweakable where Element: Tweakable {
    public static var valueTransformer: ValueTransformer<Array<Element>, String> {
        ValueTransformer(transform: { $0.map(\.stringRepresentation).joined(separator: ",") },
                         retrieve: { $0.split(separator: ",").map(String.init).compactMap(Element.init(stringRepresentation:)) })
    }
}

extension Optional: Tweakable where Wrapped: Tweakable {
    public static var valueTransformer: ValueTransformer<Self, String> {
        ValueTransformer(transform: {
            switch $0 {
                case .none: return "?nil"
                case let .some(value): return "?" + value.stringRepresentation
            }
        }, retrieve: { (string: String) -> Wrapped? in
            guard string.hasPrefix("?") else { return nil }
            let string = String(string.dropFirst())
            if string == "nil" {
                return nil
            } else {
                return Wrapped(stringRepresentation: string)
            }
        })
    }
}

public struct SectionModel<Element> {
    public var name: String
    public var elements: [Element]
    
    public init(name: String, elements: [Element]) {
        self.name = name
        self.elements = elements
    }
}
