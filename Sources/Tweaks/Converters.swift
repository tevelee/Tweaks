import Foundation
import SwiftUI

public protocol Converter {
    associatedtype RawValue
    associatedtype ConvertedValue
    func convert(_ value: RawValue) throws -> ConvertedValue
}

public struct Converting<RawValue, ConvertedValue> {
    public let _convert: (RawValue) throws -> ConvertedValue
    public init(convert: @escaping (RawValue) throws -> ConvertedValue) {
        _convert = convert
    }
    public func convert(_ value: RawValue) throws -> ConvertedValue {
        try _convert(value)
    }
    public func convert(_ value: RawValue, fallback: ConvertedValue) -> ConvertedValue {
        if let value = try? _convert(value) {
            return value
        } else {
            return fallback
        }
    }
    public func pullback<OtherValue>(_ transform: @escaping (OtherValue) -> RawValue) -> Converting<OtherValue, ConvertedValue> {
        Converting<OtherValue, ConvertedValue> { otherValue in
            let rawValue = transform(otherValue)
            return try convert(rawValue)
        }
    }
    public func chain<OtherValue>(_ other: Converting<ConvertedValue, OtherValue>) -> Converting<RawValue, OtherValue> {
        Converting<RawValue, OtherValue> { rawValue in
            let converted = try convert(rawValue)
            return try other.convert(converted)
        }
    }
    public func map<OtherValue>(_ block: @escaping (ConvertedValue) -> OtherValue) -> Converting<RawValue, OtherValue> {
        Converting<RawValue, OtherValue> { rawValue in
            let converted = try convert(rawValue)
            return block(converted)
        }
    }
}

public extension Converting where RawValue == ConvertedValue {
    static var identity: Converting<RawValue, RawValue> {
        Converting<RawValue, RawValue> { $0 }
    }
}

public struct SymmetricConvering<DecodedValue, EncodedValue> {
    public let encoding: Converting<DecodedValue, EncodedValue>
    public let decoding: Converting<EncodedValue, DecodedValue>
    
    public init(encoding: Converting<DecodedValue, EncodedValue>,
                decoding: Converting<EncodedValue, DecodedValue>) {
        self.encoding = encoding
        self.decoding = decoding
    }
    
    public init(encoding: @escaping (DecodedValue) throws -> EncodedValue,
                decoding: @escaping (EncodedValue) throws -> DecodedValue) {
        self.encoding = Converting(convert: encoding)
        self.decoding = Converting(convert: decoding)
    }
}

public extension SymmetricConvering where DecodedValue == EncodedValue {
    static var identity: SymmetricConvering<DecodedValue, DecodedValue> {
        SymmetricConvering(encoding: .identity, decoding: .identity)
    }
}

public extension Converting where RawValue == ConvertedValue? {
    static func defaultValue(_ value: ConvertedValue) -> Converting {
        Converting { $0 ?? value }
    }
}

public extension Converting where RawValue == Data, ConvertedValue == String? {
    static func string(encoding: String.Encoding) -> Converting {
        Converting { String(data: $0, encoding: encoding) }
    }
}

public extension Converting where RawValue == String, ConvertedValue == Data? {
    static func data(encoding: String.Encoding) -> Converting {
        Converting { $0.data(using: encoding) }
    }
}

public extension Converting where RawValue: LosslessStringConvertible, ConvertedValue == String {
    static var description: Converting {
        Converting(convert: \.description)
    }
}

public extension Converting where RawValue: RawRepresentable, ConvertedValue == RawValue.RawValue {
    static var rawValue: Converting {
        Converting(convert: \.rawValue)
    }
}

public extension Converting where RawValue: BinaryInteger, ConvertedValue == String {
    static var stringify: Converting {
        Converting(convert: String.init)
    }
}

public extension SymmetricConvering where DecodedValue: LosslessStringConvertible, EncodedValue == String {
    static var description: SymmetricConvering<DecodedValue, String> {
        SymmetricConvering(encoding: { $0.description },
                           decoding: {
                            guard let value = DecodedValue.init($0) else { throw ConversionError.couldNotConvert }
                            return value
                           })
    }
}

public extension SymmetricConvering where DecodedValue: RawRepresentable, EncodedValue == DecodedValue.RawValue {
    static var description: SymmetricConvering<DecodedValue, DecodedValue.RawValue> {
        SymmetricConvering(encoding: { $0.rawValue },
                           decoding: {
                            guard let value = DecodedValue(rawValue: $0) else { throw ConversionError.couldNotConvert }
                            return value
                           })
    }
}

public extension SymmetricConvering where DecodedValue: Collection, EncodedValue == String {
    static func array(converter: SymmetricConvering<DecodedValue.Element, String>) -> SymmetricConvering<[DecodedValue.Element], String> {
        SymmetricConvering<[DecodedValue.Element], String>(encoding: {
            $0.compactMap { try? converter.encoding.convert($0) }.joined(separator: ",")
        }, decoding: {
            $0.split(separator: ",").map(String.init).compactMap { try? converter.decoding.convert($0) }
        })
    }
}

public extension SymmetricConvering where EncodedValue == String {
    static func optional<Wrapped>(converter: SymmetricConvering<Wrapped, String>) -> SymmetricConvering<Wrapped?, String> {
        SymmetricConvering<Wrapped?, String>(encoding: {
            $0.flatMap { try? converter.encoding.convert($0) } ?? "nil"
        }, decoding: {
            try? converter.decoding.convert($0)
        })
    }
    
    static func array<Element>(converter: SymmetricConvering<Element, String>) -> SymmetricConvering<[Element], String> {
        SymmetricConvering<[Element], String>(encoding: {
            try $0.map(converter.encoding.convert).joined(separator: ",")
        }, decoding: {
            try $0.split(separator: ",").map(String.init).map(converter.decoding.convert)
        })
    }
}

public enum ConversionError: Error {
    case couldNotConvert
}

extension Converting where RawValue == Color, ConvertedValue == String {
    public static var hex = Converting { color in
        guard let values = color.cgColor?.components else { return "#00000000" }
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

extension Converting where RawValue == String, ConvertedValue == Color {
    public static var hex = Converting { string in
        var string = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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

        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension SymmetricConvering where DecodedValue == Color, EncodedValue == String {
    public static var hex = SymmetricConvering(encoding: .hex, decoding: .hex)
}
