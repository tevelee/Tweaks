import SwiftUI

public struct TweaksView: View {
    @ObservedObject var tweakRepository: TweakRepository
    
    public init(tweakRepository: TweakRepository = .shared) {
        self.tweakRepository = tweakRepository
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if tweakRepository.categories.isEmpty {
                    Text("No tweaks added yet")
                } else if tweakRepository.categories.count == 1 {
                    TweakCategoryDetail(category: tweakRepository.categories.first!)
                } else {
                    TweakCategoriesList()
                }
            }
        }
        .environmentObject(tweakRepository)
    }
}

struct TweakCategoriesList: View {
    @EnvironmentObject var tweakRepository: TweakRepository
    @Environment(\.highlightColor) var highlightColor
    @State var searchText: String = ""
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText, placeholderText: "Search tweaks")
            List {
                ForEach(tweakRepository.categories.search(for: searchText, in: \.name), id: \.element.name) { category, highlight in
                    NavigationLink(destination: TweakCategoryDetail(category: category)) {
                        if highlight.isEmpty {
                            Text(category.name)
                        } else {
                            StyledText(category.name)
                                .foregroundColor(Color(.secondaryLabel))
                                .style(ranges: highlight) {
                                    $0.fontWeight(.semibold).foregroundColor(Color(.label))
                                }
                        }
                    }
                }
            }
            .navigationBarTitle("Tweaks")
            .navigationBarItems(trailing: Button(action: {
                self.tweakRepository.resetAll()
            }) {
                Text("Reset all overrides")
            }.disabled(!self.tweakRepository.hasOverride()))
            .resignKeyboardOnDragGesture()
        }
    }
}

struct TweakCategoryDetail: View {
    let category: SectionModel<SectionModel<TweakDefinitionBase>>
    @EnvironmentObject var tweakRepository: TweakRepository
    @Environment(\.highlightColor) var highlightColor
    @State var searchText: String = ""
    var body: some View {
        VStack {
            SearchBar(text: $searchText, placeholderText: "Search tweaks")
            List {
                ForEach(category.elements, id: \.name) { section in
                    Group {
                        if !section.elements.search(for: self.searchText, in: \.name).isEmpty {
                            Section(header: Text(section.name)) {
                                ForEach(section.elements.search(for: self.searchText, in: \.name), id: \.element.id) { tweak, highlight in
                                    Group {
                                        if tweak.actionable != nil {
                                            TweakActionRow(tweak: tweak, highlight: highlight)
                                        } else {
                                            TweakRow(tweak: tweak, highlight: highlight)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(category.name)
            .navigationBarItems(trailing: Button(action: {
                self.tweakRepository.resetAll(in: self.category)
            }) {
                Text("Reset all overrides")
            }.disabled(!self.tweakRepository.hasOverride(in: self.category)))
            .resignKeyboardOnDragGesture()
        }
    }
}

struct TweakActionRow: View {
    let tweak: TweakDefinitionBase
    let highlight: [Range<String.Index>]

    var body: some View {
        Button(action: tweak.actionable?.action ?? {}) {
            HStack {
                if highlight.isEmpty {
                    Text(tweak.name)
                        .foregroundColor(Color(.label))
                } else {
                    StyledText(tweak.name)
                        .foregroundColor(Color(.secondaryLabel))
                        .style(ranges: highlight) {
                            $0.fontWeight(.semibold).foregroundColor(Color(.label))
                        }
                }
                Spacer()
                Image(systemName: "command")
            }
        }
    }
}

struct TweakRow: View {
    @EnvironmentObject var tweakRepository: TweakRepository
    @Environment(\.highlightColor) var highlightColor

    let tweak: TweakDefinitionBase
    let highlight: [Range<String.Index>]
    
    var viewHelper: TweakableControl? {
        tweakRepository.tweakable(for: tweak)
    }
    var isOverride: Bool { viewHelper?.isOverride() ?? false }

    var body: some View {
        NavigationLink(destination: TweakDetailView(tweakDefinition: tweak)) {
            HStack {
                if highlight.isEmpty {
                    Text(tweak.name)
                        .foregroundColor(self.isOverride ? self.highlightColor : Color(.label))
                } else {
                    StyledText(tweak.name)
                        .foregroundColor(self.isOverride ? self.highlightColor.opacity(0.7) : Color(.secondaryLabel))
                        .style(ranges: highlight) {
                            $0.fontWeight(.semibold).foregroundColor(self.isOverride ? self.highlightColor : Color(.label))
                        }
                }
                Spacer()
                self.viewHelper?.previewView()
                    .font(.subheadline)
                    .foregroundColor(self.isOverride ? self.highlightColor : Color(.secondaryLabel))
            }
        }
    }
}

struct TweaksView_Previews: PreviewProvider {
    static var previews: some View {
        TweaksView(tweakRepository: TweakRepository())
    }
}

extension Array {
    func search(for query: String, in transform: (Element) -> String, byWords: Bool = true) -> [(element: Element, highlight: [Range<String.Index>])] {
        guard !query.isEmpty else { return map { ($0, []) } }
        return compactMap { element in
            let source = transform(element)
            let queries = byWords ? query.split(separator: " ").map(String.init) : [query]
            let ranges = queries.compactMap { query -> Range<String.Index>? in
                if let range = source.range(of: query, options: [.caseInsensitive, .diacriticInsensitive], range: nil, locale: nil) {
                    return range
                } else {
                    return nil
                }
            }
            return ranges.count == queries.count ? (element, ranges) : nil
        }
    }
}

struct HighlightColorEnvironmentKey: EnvironmentKey {
    static var defaultValue: Color {
        Color(.systemOrange)
    }
}

extension EnvironmentValues {
    var highlightColor: Color {
        get {
            return self[HighlightColorEnvironmentKey]
        }
        set {
            self[HighlightColorEnvironmentKey] = newValue
        }
    }
}
