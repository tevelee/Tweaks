import Foundation
import SwiftUI

public protocol ViewRenderer {
    associatedtype Value
    associatedtype PreviewView: View
    associatedtype TweakView: View
    func previewView(value: Value) -> PreviewView
    func tweakView(value: Binding<Value>) -> TweakView
}

extension ViewRenderer where Value: Tweakable {
    public func previewView(value: Value) -> some View {
        Text(value.stringRepresentation)
    }
}

public struct ToggleBoolRenderer: ViewRenderer {
    let trueLabel: String
    let falseLabel: String
    
    public init(trueLabel: String = "true", falseLabel: String = "false") {
        self.trueLabel = trueLabel
        self.falseLabel = falseLabel
    }
    
    public func previewView(value: Bool) -> some View {
        Text(value ? trueLabel : falseLabel)
    }
    public func tweakView(value: Binding<Bool>) -> some View {
        Toggle(isOn: value) { EmptyView() }
    }
}

public struct SegmentedBoolRenderer: ViewRenderer {
    let trueLabel: String
    let falseLabel: String
    
    public init(trueLabel: String = "Yes", falseLabel: String = "No") {
        self.trueLabel = trueLabel
        self.falseLabel = falseLabel
    }
    
    public func previewView(value: Bool) -> some View {
        Text(value ? trueLabel : falseLabel)
    }
    public func tweakView(value: Binding<Bool>) -> some View {
        Picker(selection: value, label: EmptyView()) {
            Text(trueLabel).tag(true)
            Text(falseLabel).tag(false)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

public struct InputAndStepperRenderer: ViewRenderer {
    public init() {}
    public func previewView(value: Int) -> some View {
        Text(String(value))
    }
    public func tweakView(value: Binding<Int>) -> some View {
        HStack {
            TextField("", text: value.string(defaultValue: 0))
                .keyboardType(.numberPad)
            Stepper("", value: value)
        }
    }
}

extension Binding where Value: LosslessStringConvertible {
    func string(defaultValue: Value) -> Binding<String> {
        Binding<String>(get: { self.wrappedValue.description },
                        set: { self.wrappedValue = Value($0) ?? defaultValue })
    }
}

public struct SliderRenderer<Number: BinaryFloatingPoint & LosslessStringConvertible>: ViewRenderer where Number.Stride: BinaryFloatingPoint {
    let range: ClosedRange<Number>
    public init(range: ClosedRange<Number>) {
        self.range = range
    }
    public func previewView(value: Number) -> some View {
        Text(String(Number(value * 100.0).rounded() / 100.0))
    }
    public func tweakView(value: Binding<Number>) -> some View {
        Slider(value: value, in: range)
    }
}

public struct StringTextfieldRenderer: ViewRenderer {
    public init() {}
    public func previewView(value: String) -> some View {
        Text(value)
    }
    public func tweakView(value: Binding<String>) -> some View {
        TextField("", text: value)
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
}

public struct PickerRendererWithCustomValue<Value: Tweakable & Hashable, Renderer: ViewRenderer>: ViewRenderer where Renderer.Value == Value {
    public let options: [String: Value]
    public let renderer: Renderer
    public init(options: [String: Value], renderer: Renderer) {
        self.options = options
        self.renderer = renderer
    }
    public init(options: [Value], renderer: Renderer) {
        self.init(options: Dictionary(grouping: options, by:  \.stringRepresentation).compactMapValues(\.first), renderer: renderer)
    }
    public func previewView(value: Value) -> some View {
        self.renderer.previewView(value: value)
    }
    
    let sort = { (one: (key: String, Value), two: (key: String, Value)) -> Bool in
        switch (one.key, two.key) {
            case ("Custom", _): return false
            case (_, "Custom"): return true
            case let (one, two): return one < two
        }
    }
    
    public func tweakView(value: Binding<Value>) -> some View {
        var options = self.options
        options["Custom"] = value.wrappedValue
        return VStack {
            PickerRenderer(options: options, renderer: renderer, sort: sort).tweakView(value: value)
            renderer.tweakView(value: value)
        }
    }
}

public struct PickerRenderer<Value: Tweakable & Hashable, Renderer: ViewRenderer>: ViewRenderer where Renderer.Value == Value {
    public let options: [String: Value]
    public let renderer: Renderer
    public typealias Pair = (key: String, value: Value)
    public let sort: (Pair, Pair) -> Bool
    public init(options: [String: Value], renderer: Renderer, sort: @escaping (Pair, Pair) -> Bool = { $0.key < $1.key }) {
        self.options = options
        self.renderer = renderer
        self.sort = sort
    }
    public init(options: [Value], renderer: Renderer, sort: @escaping (Pair, Pair) -> Bool = { $0.key < $1.key }) {
        self.init(options: Dictionary(grouping: options, by:  \.stringRepresentation).compactMapValues(\.first), renderer: renderer, sort: sort)
    }
    public func previewView(value: Value) -> some View {
        self.renderer.previewView(value: value)
    }
    public func tweakView(value: Binding<Value>) -> some View {
        VStack {
            Picker(selection: value, label: EmptyView()) {
                ForEach(options.sorted(by: sort).map(\.key), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.body)
                            .foregroundColor(Color(.label))
                        Spacer()
                        self.renderer.previewView(value: self.options[key]!)
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .tag(self.options[key]!)
                    .disabled(self.options.values.contains(value.wrappedValue))
                }
            }
            .pickerStyle(WheelPickerStyle())
            .animation(.default)
        }
    }
}

public struct OptionPickerRenderer<Value>: ViewRenderer where Value: RawRepresentable & CaseIterable, Value.RawValue: CustomStringConvertible & Hashable {
    public init() {}
    public func previewView(value: Value) -> some View {
        Text(value.rawValue.description)
    }
    
    public func tweakView(value: Binding<Value>) -> some View {
        List {
            ForEach(Array(Value.allCases), id: \.rawValue.description) { item in
                Button(action: { value.wrappedValue = item }) {
                    HStack {
                        self.previewView(value: item)
                            .foregroundColor(Color(.label))
                        Spacer()
                        if value.wrappedValue == item {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(.systemBlue))
                        }
                    }
                }
            }
        }
    }
}

public struct ArrayRenderer<Element: Tweakable, Renderer: ViewRenderer>: ViewRenderer where Renderer.Value == Element {
    let renderer: Renderer
    let defaultValueForNewElement: Element
    public init(renderer: Renderer, defaultValueForNewElement: Element) {
        self.renderer = renderer
        self.defaultValueForNewElement = defaultValueForNewElement
    }
    public func previewView(value: [Element]) -> some View {
        Text(value.map(\.stringRepresentation).joined(separator: ", "))
    }
    public func tweakView(value: Binding<[Element]>) -> some View {
        VStack {
            ForEach(0 ..< value.wrappedValue.count, id: \.self) { index in
                HStack {
                    self.renderer.tweakView(value: value[index])
                    Image(systemName: "minus.circle")
                        .foregroundColor(Color(.systemRed))
                        .onTapGesture {
                            value.wrappedValue.remove(at: index)
                        }
                }
            }
            Button(action: { value.wrappedValue += [self.defaultValueForNewElement] }) {
                HStack {
                    Image(systemName: "plus").foregroundColor(Color(.systemBlue))
                    Text("Add")
                }
            }
        }
        .animation(.default)
    }
}

public struct OptionalToggleRenderer<Renderer: ViewRenderer, Wrapped: Tweakable>: ViewRenderer where Renderer.Value == Wrapped {
    public let renderer: Renderer
    public let defaultValueForNewValue: Wrapped
    
    public init(renderer: Renderer, defaultValueForNewValue: Wrapped) {
        self.renderer = renderer
        self.defaultValueForNewValue = defaultValueForNewValue
    }
    
    public func previewView(value: Wrapped?) -> some View {
        Group {
            if value == nil {
                Text("no value")
            } else {
                renderer.previewView(value: value!)
            }
        }
    }
    public func tweakView(value: Binding<Wrapped?>) -> some View {
        OptionalTweakView(value: value, renderer: renderer, defaultValueForNewValue: defaultValueForNewValue)
    }
}

struct OptionalTweakView<Wrapped: Tweakable, Renderer: ViewRenderer>: View where Renderer.Value == Wrapped {
    typealias Value = Wrapped?
    let value: Binding<Value>
    let renderer: Renderer
    let defaultValueForNewValue: Wrapped

    @State var lastSetValue: Wrapped?
    
    var body: some View {
        VStack {
            Toggle(isOn: Binding<Bool>(get: {
                self.value.wrappedValue != nil
            }, set: {
                if $0 {
                    self.value.wrappedValue = self.lastSetValue ?? self.defaultValueForNewValue
                } else {
                    self.value.wrappedValue = nil
                }
            })) { Text("Has value?") }
            if value.wrappedValue != nil {
                renderer.tweakView(value: Binding<Wrapped>(get: { self.value.wrappedValue! }, set: {
                    self.value.wrappedValue = $0
                    self.lastSetValue = $0
                }))
                .animation(.default)
                .transition(.opacity)
            }
        }
    }
}

public struct CustomRenderer<Value, PreviewView: View, TweakView: View>: ViewRenderer {
    let previewViewFactory: (Value) -> PreviewView
    let tweakViewFactory: (Binding<Value>) -> TweakView
    
    public init(previewView: @escaping (Value) -> PreviewView,
                tweakView: @escaping (Binding<Value>) -> TweakView) {
        self.previewViewFactory = previewView
        self.tweakViewFactory = tweakView
    }
    
    public func previewView(value: Value) -> PreviewView {
        previewViewFactory(value)
    }
    
    public func tweakView(value: Binding<Value>) -> TweakView {
        tweakViewFactory(value)
    }
}

@available(iOS 14.0, *)
public struct ColorPickerRenderer: ViewRenderer {
    public typealias Value = Color
    public init() {}
    public func previewView(value: Value) -> some View {
        value.frame(width: 30, height: 30).cornerRadius(8)
    }
    
    public func tweakView(value: Binding<Value>) -> some View {
        ColorPicker("Pick a color", selection: value)
    }
}
