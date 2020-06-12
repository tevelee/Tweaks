import Foundation
import SwiftUI

public protocol TweakRepositoryProtocol {
    func add(tweak: TweakDefinitionBase, category: String, section: String)
    func add(_ action: TweakAction)
    subscript<Value: Tweakable, Renderer: ViewRenderer>(_ definition: TweakDefinition<Value, Renderer>) -> Value? where Renderer.Value == Value { get set }
}

public class TweakRepository: ObservableObject {
    public static let shared = TweakRepository()
    
    let userDefaults: UserDefaults
    var tweaks: [String: TweakDefinitionBase] = [:]
    var categories: [SectionModel<SectionModel<TweakDefinitionBase>>] = []
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func add(tweak: TweakDefinitionBase, category: String, section: String) {
        if let existingCategory = categories.firstWithIndex(where: { $0.name == category }) {
            if let existingSection = existingCategory.element.elements.firstWithIndex(where: { $0.name == section }) {
                if let existingTweak = existingSection.element.elements.firstWithIndex(where: { $0.id == tweak.id }) {
                    categories[existingCategory.offset].elements[existingSection.offset].elements[existingTweak.offset] = tweak
                } else {
                    categories[existingCategory.offset].elements[existingSection.offset].elements.append(tweak)
                }
            } else {
                categories[existingCategory.offset].elements.append(SectionModel(name: section, elements: [tweak]))
            }
        } else {
            categories.append(SectionModel(name: category, elements: [SectionModel(name: section, elements: [tweak])]))
        }
        tweaks[tweak.id] = tweak
    }
    
    public func add(_ action: TweakAction) {
        if let actionable = action.actionable {
            add(tweak: action, category: actionable.category, section: actionable.section)
        }
    }
    
    public subscript<Value: Tweakable, Renderer: ViewRenderer>(_ definition: TweakDefinition<Value, Renderer>) -> Value? where Renderer.Value == Value {
        get {
            guard tweaks[definition.id] != nil, definition.actionable == nil else { return nil }
            if let string = userDefaults.string(forKey: definition.persistencyKey) {
                return Renderer.Value(stringRepresentation: string)
            }
            return nil
        }
        set(value) {
            guard tweaks[definition.id] != nil, definition.actionable == nil else { return }
            if let value = value, value != definition.initialValue {
                userDefaults.set(value.stringRepresentation, forKey: definition.persistencyKey)
            } else {
                userDefaults.removeObject(forKey: definition.persistencyKey)
            }
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
    func tweakable(for definition: TweakDefinitionBase) -> TweakableControl? {
        guard let tweak = tweaks[definition.id], let tweakable = tweak.tweakable(tweakRepository: self) else { return nil }
        return tweakable
    }
    func resetAll() {
        for category in categories {
            resetAll(in: category)
        }
    }
    func resetAll(in category: SectionModel<SectionModel<TweakDefinitionBase>>) {
        for section in category.elements {
            for tweak in section.elements {
                reset(tweak: tweak)
            }
        }
    }
    func reset(tweak: TweakDefinitionBase) {
        tweakable(for: tweak)?.reset()
    }
}
