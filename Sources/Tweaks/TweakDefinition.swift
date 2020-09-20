import Foundation
import SwiftUI

public protocol Tweak {
    var id: String { get }
    var name: String { get }
    func view(searchQuery: String) -> AnyView
    func viewModel(tweakRepository: TweakRepository) -> TweakViewModelProtocol
}

public struct TweakAction: Tweak {
    public let id: String
    public let name: String
    public var action: () -> Void
    
    public init(id: String = UUID().uuidString,
                name: String,
                action: @escaping () -> Void) {
        self.id = id
        self.name = name
        self.action = action
    }
    
    public func view(searchQuery: String) -> AnyView {
        AnyView(TweakActionRow(tweak: self, searchQuery: searchQuery))
    }
    
    private struct TweakActionViewModel: TweakViewModelProtocol {
        func isOverride() -> Bool { false }
        func reset() {}
    }
    
    public func viewModel(tweakRepository: TweakRepository) -> TweakViewModelProtocol {
        TweakActionViewModel()
    }
}

public protocol StorageMechanism: AnyObject {
    associatedtype Key: Hashable
    associatedtype Value
    subscript(key: Key) -> Value? { get set }
}

public struct TweakDefinition<Renderer: ViewRenderer, Store: StorageMechanism>: Tweak, Identifiable where Renderer.Value: Tweakable, Store.Key == String, Store.Value == Renderer.Value {
    public let id: String
    public let name: String
    
    public let initialValue: Renderer.Value
    public let valueRenderer: Renderer
    public let store: Store
    
    public init(id: String,
                name: String,
                initialValue: Renderer.Value,
                valueRenderer: Renderer,
                store: Store) {
        self.id = id
        self.name = name
        self.initialValue = initialValue
        self.valueRenderer = valueRenderer
        self.store = store
    }
    
    public func viewModel(tweakRepository: TweakRepository) -> TweakViewModelProtocol {
        viewModel(tweakRepository: tweakRepository) as TweakViewModel<Renderer, Store>
    }
    
    func viewModel(tweakRepository: TweakRepository) -> TweakViewModel<Renderer, Store> {
        TweakViewModel<Renderer, Store>(tweakRepository: tweakRepository, tweakDefinition: self)
    }
    
    public func view(searchQuery: String) -> AnyView {
        AnyView(TweakRow<Renderer, Store>(tweak: self, searchQuery: searchQuery))
    }
}

public class InMemoryStore<Key: Hashable, Value>: StorageMechanism {
    private var inMemoryValues: [Key: Value] = [:]
    
    public init() {}
    
    public subscript(key: Key) -> Value? {
        get {
            inMemoryValues[key]
        }
        set(value) {
            inMemoryValues[key] = value
        }
    }
}

public class UserDefaultsStore<Key: Hashable, Value>: StorageMechanism where Key: CustomStringConvertible {
    private let userDefaults: UserDefaults
    private let namespace: String
    private let converter: SymmetricConvering<Value, String>

    public init(userDefaults: UserDefaults = .standard,
                namespace: String = "default",
                converter: SymmetricConvering<Value, String>) {
        self.userDefaults = userDefaults
        self.namespace = namespace
        self.converter = converter
    }

    public subscript(key: Key) -> Value? {
        get {
            let storageKey = "\(namespace).\(key.description)"
            guard let data = userDefaults.string(forKey: storageKey) else { return nil }
            return try? converter.decoding.convert(data)
        }
        set(value) {
            let storageKey = "\(namespace).\(key.description)"
            if let value = value, let data = try? converter.encoding.convert(value) {
                userDefaults.set(data, forKey: storageKey)
            } else {
                userDefaults.removeObject(forKey: storageKey)
            }
        }
    }
}

public protocol TweakViewModelProtocol {
    func isOverride() -> Bool
    func reset()
}

public struct TweakViewModel<Renderer: ViewRenderer, Store: StorageMechanism>: TweakViewModelProtocol where Renderer.Value: Tweakable, Store.Key == String, Store.Value == Renderer.Value {
    let tweakRepository: TweakRepository
    let tweakDefinition: TweakDefinition<Renderer, Store>

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
