import SwiftUI

struct TweakDetailView: View {
    let tweakDefinition: TweakDefinitionBase
    @EnvironmentObject var tweakRepository: TweakRepository
    @Environment(\.highlightColor) var highlightColor
    
    var viewHelper: TweakableControl? {
        tweakRepository.tweakable(for: tweakDefinition)
    }
    
    var isOverride: Bool { viewHelper?.isOverride() ?? false }
    
    var body: some View {
        Form {
            Section(header: Color.clear.frame(height: 30)) {
                HStack {
                    Text("Current value")
                        .font(self.isOverride ? Font.body.bold() : Font.body)
                        .foregroundColor(isOverride ? highlightColor : Color(.label))
                    Spacer()
                    self.viewHelper?.previewView()
                }
                if self.isOverride {
                    HStack {
                        Text("Original value")
                        Spacer()
                        self.viewHelper?.previewViewForInitialValue()
                    }
                    .animation(.default)
                    .transition(.opacity)
                }
                self.viewHelper.map { control in
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(control.typeDisplayName())
                    }
                }
            }
            Section(header: Text("Tweak value")) {
                self.viewHelper?.tweakView()
            }
        }
        .navigationBarTitle(tweakDefinition.name)
        .navigationBarItems(trailing: Button(action: { self.viewHelper?.reset() }) {
            Text("Reset override")
        }.disabled(!isOverride))
    }
}

struct TweakDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let tweak = TweakDefinition(name: "Test", initialValue: 2, valueRenderer: InputAndStepperRenderer())
        return TweakDetailView(tweakDefinition: tweak)
    }
}
