import Foundation
import SwiftUI

public struct TextStyle {
    let range: Range<String.Index>
    let apply: (Text) -> Text
}

extension String {
    var fullRange: Range<Index> {
        startIndex ..< endIndex
    }
    func index(at offset: Int) -> Index {
        index(startIndex, offsetBy: offset)
    }
}

public struct StyledText: View {
    let text: String
    let styles: [TextStyle]
    
    @Environment(\.font) var font
    
    init(_ text: String, styles: [TextStyle] = []) {
        self.text = text
        self.styles = styles
    }
    
    public var body: some View {
        let allStyles = [TextStyle(range: text.fullRange) { $0.font(font) }] + styles
        return text.enumerated().reduce(Text(verbatim: "")) { result, character in
            result + allStyles
                .filter { $0.range.contains(text.index(at: character.offset)) }
                .reduce(Text(String(character.element))) { formatted, style in
                    style.apply(formatted)
                }
        }
        .accessibility(label: Text(text))
        .accessibility(addTraits: .isStaticText)
    }
    
    public func font(_ font: Font?) -> StyledText {
        apply { $0.font(font) }
    }
    
    public func foregroundColor(_ color: Color?) -> StyledText {
        apply { $0.foregroundColor(color) }
    }
    
    func apply(block: @escaping (Text) -> Text) -> StyledText {
        let style = TextStyle(range: text.fullRange, apply: block)
        return StyledText(text, styles: [style] + styles)
    }
}

extension StyledText {
    func style(ranges: [Range<String.Index>]? = nil, apply: @escaping (Text) -> Text) -> StyledText {
        let newStyles = (ranges ?? [text.fullRange]).map { TextStyle(range: $0, apply: apply) }
        return StyledText(text, styles: newStyles + styles)
    }
}
