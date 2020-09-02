import Foundation
import SwiftUI

public protocol Tweak {
    var id: UUID { get }
    var name: String { get }
    func view(searchQuery: String) -> AnyView
}

public struct TweakAction: Tweak, Equatable {
    public let id: UUID
    public let name: String
    public var action: () -> Void
    
    public init(id: UUID = UUID(),
                name: String,
                action: @escaping () -> Void) {
        self.id = id
        self.name = name
        self.action = action
    }
    
    public func view(searchQuery: String) -> AnyView {
        AnyView(TweakActionRow(tweak: self, searchQuery: searchQuery))
    }
    
    public static func == (lhs: TweakAction, rhs: TweakAction) -> Bool {
        lhs.id == rhs.id
    }
}

public struct TweakDefinition<Renderer: ViewRenderer>: Tweak, Identifiable, Equatable where Renderer.Value: Tweakable {
    public let id: UUID
    public let name: String
    
    public let initialValue: Renderer.Value
    public let valueRenderer: Renderer
    public let valueTransformer: ValueTransformer<Renderer.Value, String>
    
    public init(id: UUID = UUID(),
                name: String,
                initialValue: Renderer.Value,
                valueRenderer: Renderer,
                valueTransformer: ValueTransformer<Renderer.Value, String> = Renderer.Value.valueTransformer) {
        self.id = id
        self.name = name
        self.initialValue = initialValue
        self.valueRenderer = valueRenderer
        self.valueTransformer = valueTransformer
    }
    
    public func viewModel(tweakRepository: TweakRepository) -> TweakViewModel<Renderer> {
        TweakViewModel(tweakRepository: tweakRepository, tweakDefinition: self)
    }
    
    public func view(searchQuery: String) -> AnyView {
        AnyView(TweakRow(tweak: self, searchQuery: searchQuery))
    }
    
    public static func == (lhs: TweakDefinition<Renderer>, rhs: TweakDefinition<Renderer>) -> Bool {
        lhs.id == rhs.id
    }
}

extension TweakDefinition {
    var persistencyKey: String { "tweaks.\(id)" }
}

public struct TweakViewModel<Renderer: ViewRenderer> where Renderer.Value: Tweakable {
    let tweakRepository: TweakRepository
    let tweakDefinition: TweakDefinition<Renderer>

    private func value() -> Renderer.Value {
        tweakRepository[tweakDefinition] ?? tweakDefinition.initialValue
    }

    public func previewView() -> Renderer.PreviewView {
        previewView(value: value())
    }

    public func previewViewForInitialValue() -> Renderer.PreviewView {
        previewView(value: tweakDefinition.initialValue)
    }

    private func previewView(value: Renderer.Value) -> Renderer.PreviewView {
        tweakDefinition.valueRenderer.previewView(value: value)
    }

    public func tweakView() -> Renderer.TweakView {
        tweakDefinition.valueRenderer.tweakView(value: Binding(get: {
            self.value()
        }, set: { value in
            self.tweakRepository[self.tweakDefinition] = value
        }))
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
    init(id: UUID = UUID(),
         name: String,
         initialValue: Bool,
         valueTransformer: ValueTransformer<Bool, String> = Bool.valueTransformer) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: ToggleBoolRenderer(), valueTransformer: valueTransformer)
    }
}

public extension TweakDefinition where Renderer == InputAndStepperRenderer {
    init(id: UUID = UUID(),
         name: String,
         initialValue: Int,
         valueTransformer: ValueTransformer<Int, String> = Int.valueTransformer) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: InputAndStepperRenderer(), valueTransformer: valueTransformer)
    }
}

public extension TweakDefinition where Renderer == SliderRenderer<Double> {
    init(id: UUID = UUID(),
         name: String,
         initialValue: Double,
         valueTransformer: ValueTransformer<Double, String> = Double.valueTransformer,
         range: ClosedRange<Double> = 0 ... 1) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: SliderRenderer(range: range), valueTransformer: valueTransformer)
    }
}

public extension TweakDefinition where Renderer == StringTextfieldRenderer {
    init(id: UUID = UUID(),
         name: String,
         initialValue: String,
         valueTransformer: ValueTransformer<String, String> = String.valueTransformer) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: StringTextfieldRenderer(), valueTransformer: valueTransformer)
    }
}

public extension TweakDefinition {
    init<Wrapped: Tweakable, InnerRenderer: ViewRenderer>(id: UUID = UUID(),
         name: String,
         initialValue: Wrapped?,
         valueTransformer: ValueTransformer<Wrapped?, String> = Wrapped?.valueTransformer,
         renderer: InnerRenderer,
         defaultValueForNewValue: Wrapped) where Renderer == OptionalToggleRenderer<InnerRenderer, Wrapped> {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: OptionalToggleRenderer(renderer: renderer, defaultValueForNewValue: defaultValueForNewValue), valueTransformer: valueTransformer)
    }
    
    init<Wrapped: Tweakable, InnerRenderer: ViewRenderer>(id: UUID = UUID(),
         name: String,
         initialValue: [Wrapped],
         valueTransformer: ValueTransformer<[Wrapped], String> = [Wrapped].valueTransformer,
         renderer: InnerRenderer,
         defaultValueForNewElement: Wrapped) where Renderer == ArrayRenderer<Wrapped, InnerRenderer> {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: ArrayRenderer(renderer: renderer, defaultValueForNewElement: defaultValueForNewElement), valueTransformer: valueTransformer)
    }
}

public extension TweakDefinition where Renderer == ArrayRenderer<Int, InputAndStepperRenderer> {
    init(id: UUID = UUID(),
         name: String,
         initialValue: [Int],
         valueTransformer: ValueTransformer<[Int], String> = [Int].valueTransformer,
         defaultValueForNewElement: Int = 0) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: ArrayRenderer(renderer: InputAndStepperRenderer(), defaultValueForNewElement: defaultValueForNewElement), valueTransformer: valueTransformer)
    }
}

public extension TweakDefinition {
    init<Value>(id: UUID = UUID(),
         name: String,
         initialValue: Value,
         valueTransformer: ValueTransformer<Value, String> = Value.valueTransformer) where Renderer == OptionPickerRenderer<Value>, Renderer.Value: CaseIterable & RawRepresentable, Value.RawValue: CustomStringConvertible & Hashable {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: OptionPickerRenderer(), valueTransformer: valueTransformer)
    }
}

@available(iOS 14.0, *)
public extension TweakDefinition where Renderer == ColorPickerRenderer {
    init(id: UUID = UUID(),
         name: String,
         initialValue: Color,
         valueTransformer: ValueTransformer<Color, String> = Color.valueTransformer) {
        self.init(id: id, name: name, initialValue: initialValue, valueRenderer: ColorPickerRenderer(), valueTransformer: valueTransformer)
    }
}
