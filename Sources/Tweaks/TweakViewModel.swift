import Foundation
import SwiftUI

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
            value()
        }, set: { value in
            tweakRepository[tweakDefinition] = value
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
