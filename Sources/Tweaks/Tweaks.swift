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

public struct TweakDefinition<Renderer: ViewRenderer, Store: StorageMechanism>: Tweak, Identifiable where Renderer.Value: Tweakable, Store.Key == String, Store.Value == Renderer.Value {
    public let id: String
    public let name: String
    
    public let initialValue: Renderer.Value
    public let renderer: Renderer
    public let store: Store
    
    public init(id: String,
                name: String,
                initialValue: Renderer.Value,
                renderer: Renderer,
                store: Store) {
        self.id = id
        self.name = name
        self.initialValue = initialValue
        self.renderer = renderer
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
