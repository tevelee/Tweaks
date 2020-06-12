import Foundation
import SwiftUI

public protocol TweakDefinitionBase {
    var id: String { get }
    var name: String { get }
    var actionable: ActionableControl? { get }
    func tweakable(tweakRepository: TweakRepository) -> TweakableControl?
}

public struct ActionableControl {
    var category: String
    var section: String
    var action: () -> Void
}

public protocol TweakableControl {
    func previewView() -> AnyView
    func previewViewForInitialValue() -> AnyView
    func tweakView() -> AnyView
    func typeDisplayName() -> String
    func isOverride() -> Bool
    func reset()
}

public struct TweakAction: TweakDefinitionBase {
    public let id: String
    public let name: String
    public let actionable: ActionableControl?
    
    public init(id: String = UUID().uuidString,
                category: String,
                section: String,
                name: String,
                action: @escaping () -> Void) {
        self.id = id
        self.name = name
        self.actionable = ActionableControl(category: category, section: section, action: action)
    }
    
    public func tweakable(tweakRepository: TweakRepository) -> TweakableControl? {
        nil
    }
}

public protocol TweakDefinitionGenericBase: Identifiable {
    associatedtype Value: Tweakable
    associatedtype Renderer: ViewRenderer where Renderer.Value == Value
    var initialValue: Value { get }
    var valueRenderer: Renderer { get }
    var valueTransformer: ValueTransformer<Value, String> { get }
}

public struct TweakDefinition<Value: Tweakable, Renderer: ViewRenderer>: TweakDefinitionBase, TweakDefinitionGenericBase where Renderer.Value == Value {
    public let id: String
    public let name: String
    public var actionable: ActionableControl? { nil }
    
    public let initialValue: Value
    public let valueRenderer: Renderer
    public let valueTransformer: ValueTransformer<Value, String>
    
    public init(id: String = UUID().uuidString,
                name: String,
                initialValue: Value,
                valueRenderer: Renderer,
                valueTransformer: ValueTransformer<Value, String> = Value.valueTransformer) {
        self.id = id
        self.name = name
        self.initialValue = initialValue
        self.valueRenderer = valueRenderer
        self.valueTransformer = valueTransformer
    }
    
    public func tweakable(tweakRepository: TweakRepository) -> TweakableControl? {
        TweakUIHelper(tweakRepository: tweakRepository, tweakDefinition: self)
    }
}

extension TweakDefinition {
    var persistencyKey: String { "tweaks.\(id)" }
}

struct TweakUIHelper<Value: Tweakable, Renderer: ViewRenderer>: TweakableControl where Renderer.Value == Value {
    let tweakRepository: TweakRepository
    let tweakDefinition: TweakDefinition<Value, Renderer>
    
    private func value() -> Renderer.Value {
        tweakRepository[tweakDefinition] ?? tweakDefinition.initialValue
    }
    
    public func previewView() -> AnyView {
        previewView(value: value())
    }
    
    public func previewViewForInitialValue() -> AnyView {
        previewView(value: tweakDefinition.initialValue)
    }
    
    func previewView(value: Renderer.Value) -> AnyView {
        AnyView(tweakDefinition.valueRenderer.previewView(value: value))
    }
    
    public func tweakView() -> AnyView {
        AnyView(tweakDefinition.valueRenderer.tweakView(value: Binding(get: {
            self.value()
        }, set: { value in
            self.tweakRepository[self.tweakDefinition] = value
        })))
    }
    
    public func typeDisplayName() -> String {
        String(describing: type(of: value()))
    }
    
    public func isOverride() -> Bool {
        tweakRepository[tweakDefinition] != nil
    }
    
    public func reset() {
        tweakRepository[tweakDefinition] = nil
    }
}

public extension TweakDefinition where Renderer == ToggleBoolRenderer {
    init(id: String = UUID().uuidString,
         name: String,
         initialValue: Value,
         valueTransformer: ValueTransformer<Value, String> = Value.valueTransformer) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: ToggleBoolRenderer(), valueTransformer: valueTransformer)
    }
}

public extension TweakDefinition where Renderer == InputAndStepperRenderer {
    init(id: String = UUID().uuidString,
         name: String,
         initialValue: Value,
         valueTransformer: ValueTransformer<Value, String> = Value.valueTransformer) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: InputAndStepperRenderer(), valueTransformer: valueTransformer)
    }
}

public extension TweakDefinition where Renderer == SliderRenderer<Value>, Value == Double {
    init(id: String = UUID().uuidString,
         name: String,
         initialValue: Value,
         valueTransformer: ValueTransformer<Value, String> = Value.valueTransformer,
         range: ClosedRange<Double> = 0 ... 1) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: SliderRenderer(range: range), valueTransformer: valueTransformer)
    }
}

public extension TweakDefinition where Renderer == StringTextfieldRenderer {
    init(id: String = UUID().uuidString,
         name: String,
         initialValue: Value,
         valueTransformer: ValueTransformer<Value, String> = Value.valueTransformer) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: StringTextfieldRenderer(), valueTransformer: valueTransformer)
    }
}

//public extension ConfigDefinition {
//    func tweak<Wrapped: Tweakable, Renderer: ViewRenderer>(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared, renderer: Renderer, defaultValueForNew: Wrapped) -> ConfigDefinition where Value == Wrapped?, Renderer.Value == Wrapped {
//        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: OptionalToggleRenderer(renderer: renderer, defaultValueForNew: defaultValueForNew))
//    }
//
//    func tweak<Element: Tweakable, Renderer: ViewRenderer>(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared, renderer: Renderer, defaultValueForNewElement: Element) -> ConfigDefinition where Value == [Element], Renderer.Value == Element {
//        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: ArrayRenderer(renderer: renderer, defaultValueForNewElement: defaultValueForNewElement))
//    }
//}
//
//public extension ConfigDefinition where Value == [Int] {
//    func tweak(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared, defaultValueForNewElement: Int = 0) -> ConfigDefinition {
//        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: ArrayRenderer(renderer: InputAndStepperRenderer(), defaultValueForNewElement: defaultValueForNewElement))
//    }
//}
//
//public extension ConfigDefinition where Value: Tweakable & CaseIterable & RawRepresentable, Value.RawValue: CustomStringConvertible & Hashable {
//    func tweak(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared) -> ConfigDefinition {
//        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: OptionPickerRenderer())
//    }
//}
