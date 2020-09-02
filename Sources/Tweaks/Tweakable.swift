import Foundation
import SwiftUI

public struct ValueTransformer<Source, Destination> {
    public let transform: (Source) -> Destination
    public let retrieve: (Destination) -> Source?
    
    public init(transform: @escaping (Source) -> Destination,
                retrieve: @escaping (Destination) -> Source?) {
        self.transform = transform
        self.retrieve = retrieve
    }
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

extension Color: Tweakable {
    public static var valueTransformer: Tweaks.ValueTransformer<Color, String> {
        Tweaks.ValueTransformer(transform: \.hexValue, retrieve: Color.init(hex:))
    }
    
    init(hex string: String) {
        var string: String = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if string.hasPrefix("#") {
            _ = string.removeFirst()
        }

        let scanner = Scanner(string: string)

        var color: UInt64 = 0
        scanner.scanHexInt64(&color)

        let mask = 0x000000FF
        let r = Int(color >> 24) & mask
        let g = Int(color >> 16) & mask
        let b = Int(color >> 8) & mask
        let a = Int(color) & mask

        let red = Double(r) / 255.0
        let green = Double(g) / 255.0
        let blue = Double(b) / 255.0
        let alpha = Double(a) / 255.0

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
    
    var hexValue: String {
        guard let values = cgColor?.components else { return "#00000000" }
        let outputR = Int(values[0] * 255)
        let outputG = Int(values[1] * 255)
        let outputB = Int(values[2] * 255)
        let outputA = Int(values[3] * 255)
        return "#"
            + String(format:"%02X", outputR)
            + String(format:"%02X", outputG)
            + String(format:"%02X", outputB)
            + String(format:"%02X", outputA)
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
