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
                let searchResults = tweakRepository.categories.search(for: searchText, in: \.name)
                ForEach(searchResults, id: \.name) { category in
                    NavigationLink(destination: TweakCategoryDetail(category: category)) {
                        let highlightRanges = category.name.ranges(for: searchText)
                        if highlightRanges.isEmpty {
                            Text(category.name)
                        } else {
                            StyledText(category.name)
                                .foregroundColor(Color(.secondaryLabel))
                                .style(ranges: highlightRanges) {
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
    let category: SectionModel<SectionModel<Tweak>>
    @EnvironmentObject var tweakRepository: TweakRepository
    @Environment(\.highlightColor) var highlightColor
    @State var searchText: String = ""
    var body: some View {
        VStack {
            SearchBar(text: $searchText, placeholderText: "Search tweaks")
            List {
                ForEach(category.elements, id: \.name) { section in
                    let searchResults = section.elements.search(for: searchText, in: \.name)
                    if !searchResults.isEmpty {
                        Section(header: Text(section.name)) {
                            ForEach(searchResults, id: \.id) { tweak in
                                tweak.view(searchQuery: searchText)
                            }
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .resignKeyboardOnDragGesture()
        }
        .navigationBarTitle(category.name)
        .navigationBarItems(trailing: Button(action: {
            self.tweakRepository.resetAll(in: self.category)
        }) {
            Text("Reset all overrides")
        }.disabled(!self.tweakRepository.hasOverride(in: self.category)))
    }
}

struct HasResult: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct TweakActionRow: View, Equatable {
    let tweak: TweakAction
    let searchQuery: String

    var body: some View {
        Button(action: tweak.action) {
            HStack {
                let highlightRanges = tweak.name.ranges(for: searchQuery)
                if highlightRanges.isEmpty {
                    Text(tweak.name)
                        .foregroundColor(Color(.label))
                } else {
                    StyledText(tweak.name)
                        .foregroundColor(Color(.secondaryLabel))
                        .style(ranges: highlightRanges) {
                            $0.fontWeight(.semibold).foregroundColor(Color(.label))
                        }
                }
                Spacer()
                Image(systemName: "command")
            }
        }
    }
}

struct TweakRow<Renderer: ViewRenderer>: View, Equatable where Renderer.Value: Tweakable {
    @EnvironmentObject var tweakRepository: TweakRepository
    @Environment(\.highlightColor) var highlightColor

    let tweak: TweakDefinition<Renderer>
    let searchQuery: String
    
    var viewModel: TweakViewModel<Renderer> {
        tweak.viewModel(tweakRepository: tweakRepository)
    }

    var body: some View {
        NavigationLink(destination: TweakDetailView(tweakDefinition: tweak)) {
            HStack {
                let highlightRanges = tweak.name.ranges(for: searchQuery)
                if highlightRanges.isEmpty {
                    Text(tweak.name)
                        .foregroundColor(viewModel.isOverride() ? self.highlightColor : Color(.label))
                } else {
                    StyledText(tweak.name)
                        .foregroundColor(viewModel.isOverride() ? self.highlightColor.opacity(0.7) : Color(.secondaryLabel))
                        .style(ranges: highlightRanges) {
                            $0.fontWeight(.semibold).foregroundColor(viewModel.isOverride() ? self.highlightColor : Color(.label))
                        }
                }
                Spacer()
                viewModel.previewView()
                    .font(.subheadline)
                    .foregroundColor(viewModel.isOverride() ? self.highlightColor : Color(.secondaryLabel))
            }
        }
    }
    
    static func == (lhs: TweakRow<Renderer>, rhs: TweakRow<Renderer>) -> Bool {
        lhs.tweak == rhs.tweak && lhs.searchQuery == rhs.searchQuery
    }
}

struct TweaksView_Previews: PreviewProvider {
    static var previews: some View {
        TweaksView(tweakRepository: TweakRepository())
    }
}

extension Array {
    func search(for query: String, in field: (Element) -> String, byWords: Bool = true) -> Array {
        guard !query.isEmpty else { return self }
        return filter { field($0).matches(query: query, byWords: true) }
    }
}

extension String {
    func matches(query: String, byWords: Bool = true) -> Bool {
        !ranges(for: query, byWords: byWords).isEmpty
    }
    
    func ranges(for query: String, byWords: Bool = true) -> [Range<String.Index>] {
        guard !query.isEmpty else { return [] }
        let queries = byWords ? query.split(separator: " ").map(String.init) : [query]
        let ranges = queries.compactMap { query -> Range<String.Index>? in
            if let range = range(of: query, options: [.caseInsensitive, .diacriticInsensitive], range: nil, locale: nil) {
                return range
            } else {
                return nil
            }
        }
        guard ranges.count == queries.count else { return [] }
        return ranges
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
