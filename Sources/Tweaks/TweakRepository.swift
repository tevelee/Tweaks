import Foundation
import SwiftUI

public protocol TweakRepositoryProtocol: AnyObject {
    func add(_ hierarchy: TweakHierarchy)
    subscript<Renderer: ViewRenderer, Store: StorageMechanism>(_ definition: TweakDefinition<Renderer, Store>) -> Renderer.Value? where Renderer.Value: Tweakable, Store.Key == String, Store.Value == Renderer.Value { get set }
}

public extension TweakRepositoryProtocol {
    func add(tweak: Tweak, category: String, section: String) {
        add(TweakHierarchy(tweak: tweak, category: category, section: section))
    }
}

public struct TweakHierarchy {
    public let tweak: Tweak
    public let category: String
    public let section: String
    
    public init(tweak: Tweak,
                category: String,
                section: String) {
        self.tweak = tweak
        self.category = category
        self.section = section
    }
}

public class TweakRepository: ObservableObject, TweakRepositoryProtocol {
    public static let shared = TweakRepository()
    
    var tweaks: [String: Tweak] = [:]
    var categories: [SectionModel<SectionModel<Tweak>>] = []
    
    public init() {}
    
    public func add(_ hierarchy: TweakHierarchy) {
        if let existingCategory = categories.firstWithIndex(where: { $0.name == hierarchy.category }) {
            if let existingSection = existingCategory.element.elements.firstWithIndex(where: { $0.name == hierarchy.section }) {
                if let existingTweak = existingSection.element.elements.firstWithIndex(where: { $0.id == hierarchy.tweak.id }) {
                    categories[existingCategory.offset].elements[existingSection.offset].elements[existingTweak.offset] = hierarchy.tweak
                } else {
                    categories[existingCategory.offset].elements[existingSection.offset].elements.append(hierarchy.tweak)
                }
            } else {
                categories[existingCategory.offset].elements.append(SectionModel(name: hierarchy.section, elements: [hierarchy.tweak]))
            }
        } else {
            categories.append(SectionModel(name: hierarchy.category, elements: [SectionModel(name: hierarchy.section, elements: [hierarchy.tweak])]))
        }
        tweaks[hierarchy.tweak.id] = hierarchy.tweak
    }

    public subscript<Renderer: ViewRenderer, Store: StorageMechanism>(_ definition: TweakDefinition<Renderer, Store>) -> Renderer.Value? where Renderer.Value: Tweakable, Store.Key == String, Store.Value == Renderer.Value {
        get {
            guard tweaks[definition.id] != nil else { return nil }
            return definition.store[definition.id]
        }
        set(value) {
            guard tweaks[definition.id] != nil else { return }
            definition.store[definition.id] = value
            objectWillChange.send()
        }
    }
}

extension Array {
    func firstWithIndex(where block: @escaping (Element) -> Bool) -> (offset: Int, element: Element)? {
        for item in enumerated() where block(item.element) {
            return item
        }
        return nil
    }
}

extension TweakRepository {
    func resetAll() {
        for category in categories {
            resetAll(in: category)
        }
    }
    func resetAll(in category: SectionModel<SectionModel<Tweak>>) {
        for section in category.elements {
            for tweak in section.elements {
                reset(tweak: tweak)
            }
        }
    }
    func hasOverride() -> Bool {
        categories.contains {
            self.hasOverride(in: $0)
        }
    }
    func hasOverride(in category: SectionModel<SectionModel<Tweak>>) -> Bool {
        category.elements.contains {
            $0.elements.contains {
                $0.viewModel(tweakRepository: self).isOverride()
            }
        }
    }
    func reset(tweak: Tweak) {
        tweak.viewModel(tweakRepository: self).reset()
    }
}
