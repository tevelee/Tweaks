import Foundation
import SwiftUI

public extension TweakDefinition where Renderer == ToggleBoolRenderer, Store == UserDefaultsStore<String, Renderer.Value> {
    init(id: String,
         name: String,
         initialValue: Bool) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: ToggleBoolRenderer(), store: UserDefaultsStore(converter: .description))
    }
}

public extension TweakDefinition where Renderer == ToggleBoolRenderer, Store == InMemoryStore<String, Renderer.Value> {
    init(name: String,
         initialValue: Bool) {
        self.init(id: UUID().uuidString, name: name, initialValue: initialValue, valueRenderer: ToggleBoolRenderer(), store: InMemoryStore())
    }
}

public extension TweakDefinition where Renderer == InputAndStepperRenderer, Store == UserDefaultsStore<String, Renderer.Value> {
    init(id: String,
         name: String,
         initialValue: Int) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: InputAndStepperRenderer(), store: UserDefaultsStore(converter: .description))
    }
}

public extension TweakDefinition where Renderer == InputAndStepperRenderer, Store == InMemoryStore<String, Renderer.Value> {
    init(name: String,
         initialValue: Int) {
        self.init(id: UUID().uuidString, name: name, initialValue: initialValue, valueRenderer: InputAndStepperRenderer(), store: InMemoryStore())
    }
}

public extension TweakDefinition where Renderer == SliderRenderer<Double>, Store == UserDefaultsStore<String, Renderer.Value> {
    init(id: String,
         name: String,
         initialValue: Double,
         range: ClosedRange<Double> = 0 ... 1) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: SliderRenderer(range: range), store: UserDefaultsStore(converter: .description))
    }
}

public extension TweakDefinition where Renderer == SliderRenderer<Double>, Store == InMemoryStore<String, Renderer.Value> {
    init(name: String,
         initialValue: Double,
         range: ClosedRange<Double> = 0 ... 1) {
        self.init(id: UUID().uuidString, name: name, initialValue: initialValue, valueRenderer: SliderRenderer(range: range), store: InMemoryStore())
    }
}

public extension TweakDefinition where Renderer == StringTextfieldRenderer, Store == UserDefaultsStore<String, Renderer.Value> {
    init(id: String,
         name: String,
         initialValue: String) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: StringTextfieldRenderer(), store: UserDefaultsStore(converter: .identity))
    }
}

public extension TweakDefinition where Renderer == StringTextfieldRenderer, Store == InMemoryStore<String, Renderer.Value> {
    init(name: String,
         initialValue: String) {
        self.init(id: UUID().uuidString, name: name, initialValue: initialValue, valueRenderer: StringTextfieldRenderer(), store: InMemoryStore())
    }
}

public extension TweakDefinition {
    init<InnerRenderer: ViewRenderer>(id: String,
         name: String,
         initialValue: InnerRenderer.Value? = nil,
         renderer: InnerRenderer,
         defaultValueForNewElement: InnerRenderer.Value,
         converter: SymmetricConvering<InnerRenderer.Value, String>) where Renderer == OptionalToggleRenderer<InnerRenderer>, Store == UserDefaultsStore<String, Renderer.Value> {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: OptionalToggleRenderer(renderer: renderer, defaultValueForNewElement: defaultValueForNewElement), store: UserDefaultsStore(converter: .optional(converter: converter)))
    }
    
    init<InnerRenderer: ViewRenderer>(name: String,
         initialValue: InnerRenderer.Value? = nil,
         renderer: InnerRenderer,
         defaultValueForNewElement: InnerRenderer.Value,
         converter: SymmetricConvering<InnerRenderer.Value, String>) where Renderer == OptionalToggleRenderer<InnerRenderer>, Store == InMemoryStore<String, Renderer.Value> {
        self.init(id: UUID().uuidString, name: name, initialValue: initialValue, valueRenderer: OptionalToggleRenderer(renderer: renderer, defaultValueForNewElement: defaultValueForNewElement), store: InMemoryStore())
    }
    
    init<InnerRenderer: ViewRenderer>(id: String,
         name: String,
         initialValue: [InnerRenderer.Value],
         renderer: InnerRenderer,
         defaultValueForNewElement: InnerRenderer.Value,
         converter: SymmetricConvering<InnerRenderer.Value, String>) where Renderer == ArrayRenderer<InnerRenderer>, Store == UserDefaultsStore<String, Renderer.Value> {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: ArrayRenderer(renderer: renderer, converter: converter.encoding, defaultValueForNewElement: defaultValueForNewElement), store: UserDefaultsStore(converter: .array(converter: converter)))
    }
}

public extension TweakDefinition where Renderer == ArrayRenderer<InputAndStepperRenderer>, Store == UserDefaultsStore<String, Renderer.Value> {
    init(id: String,
         name: String,
         initialValue: [Int],
         defaultValueForNewElement: Int = 0) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: ArrayRenderer(renderer: InputAndStepperRenderer(), converter: .stringify, defaultValueForNewElement: defaultValueForNewElement), store: UserDefaultsStore(converter: .array(converter: .description)))
    }
}

public extension TweakDefinition {
    init<Value>(id: String,
                name: String,
                initialValue: Value,
                converter: SymmetricConvering<Value, String>) where Renderer == OptionPickerRenderer<Value>, Renderer.Value: CaseIterable, Store == UserDefaultsStore<String, Renderer.Value> {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: OptionPickerRenderer(converter: converter.encoding), store: UserDefaultsStore(converter: converter))
    }
    
    init<Value>(name: String,
                initialValue: Value,
                converter: SymmetricConvering<Value, String>) where Renderer == OptionPickerRenderer<Value>, Renderer.Value: CaseIterable, Store == InMemoryStore<String, Renderer.Value> {
        self.init(id: UUID().uuidString, name: name, initialValue: initialValue, valueRenderer: OptionPickerRenderer(converter: converter.encoding), store: InMemoryStore())
    }
}

@available(iOS 14.0, *)
public extension TweakDefinition where Renderer == ColorPickerRenderer, Store == UserDefaultsStore<String, Renderer.Value> {
    init(id: String,
         name: String,
         initialValue: Color) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: ColorPickerRenderer(), store: UserDefaultsStore(converter: .hex))
    }
}

@available(iOS 14.0, *)
public extension TweakDefinition where Renderer == ColorPickerRenderer, Store == InMemoryStore<String, Renderer.Value> {
    init(name: String,
         initialValue: Color) {
        self.init(id: UUID().uuidString, name: name, initialValue: initialValue, valueRenderer: ColorPickerRenderer(), store: InMemoryStore())
    }
}
