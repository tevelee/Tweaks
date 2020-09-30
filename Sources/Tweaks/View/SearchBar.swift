import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SearchBar: View {
    @Binding var text: String
    @ObservedObject var keyboard = Keyboard.shared
    var placeholderText = "Search"
        
    var body: some View {
        HStack {
            TextField(placeholderText, text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .disableAutocorrection(true)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if text != "" {
                            Button(action: { text = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
            if keyboard.isVisible {
                Button(action: {
                    text = ""
                    UIApplication.shared.endEditing()
                }) {
                    Text("Cancel")
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.default)
        .padding(.horizontal)
        .clipped()
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(text: .constant("test"))
    }
}

extension UIApplication {
    func endEditing(force: Bool = true) {
        windows
            .filter{$0.isKeyWindow}
            .first?
            .endEditing(force)
    }
}

extension View {
    func resignKeyboardOnDragGesture() -> some View {
        gesture(DragGesture().onChanged { _ in
            UIApplication.shared.endEditing()
        })
    }
}

final class Keyboard: ObservableObject {
    public static let shared = Keyboard()
    private var notificationCenter: NotificationCenter
    @Published private(set) var currentHeight: CGFloat = 0
    @Published private(set) var isVisible = false

    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc func keyBoardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            currentHeight = keyboardSize.height
        }
        isVisible = true
    }

    @objc func keyBoardWillHide(notification: Notification) {
        currentHeight = 0
        isVisible = false
    }
}
