import SwiftUI

struct TweakDetailView<Renderer: ViewRenderer, Store: StorageMechanism>: View where Renderer.Value: Tweakable, Store.Key == String, Store.Value == Renderer.Value {
    let tweakDefinition: TweakDefinition<Renderer, Store>
    @EnvironmentObject var tweakRepository: TweakRepository
    @Environment(\.highlightColor) var highlightColor
    
    var viewModel: TweakViewModel<Renderer, Store> {
        tweakDefinition.viewModel(tweakRepository: tweakRepository)
    }
    
    var body: some View {
        Form {
            Section(header: Color.clear.frame(height: 30)) {
                HStack {
                    Text("Current value")
                        .font(viewModel.isOverride() ? Font.body.bold() : Font.body)
                        .foregroundColor(viewModel.isOverride() ? highlightColor : Color(.label))
                    Spacer()
                    viewModel.previewView()
                }
                if viewModel.isOverride() {
                    HStack {
                        Text("Original value")
                        Spacer()
                        viewModel.previewViewForInitialValue()
                    }
                    .animation(.default)
                    .transition(.opacity)
                }
                HStack {
                    Text("Type")
                    Spacer()
                    Text(viewModel.typeDisplayName())
                }
            }
            Section(header: Text("Tweak value")) {
                viewModel.tweakView()
            }
        }
        .navigationBarTitle(tweakDefinition.name)
        .navigationBarItems(trailing: Button(action: viewModel.reset) {
            Text("Reset override")
        }.disabled(!viewModel.isOverride()))
    }
}

struct TweakDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let tweak = TweakDefinition(id: "preview", name: "Test", initialValue: 2, renderer: InputAndStepperRenderer(), store: InMemoryStore())
        return TweakDetailView(tweakDefinition: tweak)
    }
}
