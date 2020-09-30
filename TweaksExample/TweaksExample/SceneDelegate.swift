//
//  SceneDelegate.swift
//  TweaksExample
//
//  Created by László Teveli on 2020. 06. 12..
//  Copyright © 2020. Laszlo Teveli. All rights reserved.
//

import UIKit
import SwiftUI
import Tweaks

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        let name = TweakDefinition(id: "t1", name: "Name", initialValue: "default name")
        let enabled = TweakDefinition(id: "t2", name: "Is Enabled", initialValue: false, renderer: SegmentedBoolRenderer(), store: UserDefaultsStore(converter: .description))
        let flag = TweakDefinition(name: "Flag", initialValue: true)
        let numberOfItems = TweakDefinition(id: "t3", name: "Number of items", initialValue: 1)
        let chartOffset = TweakDefinition(id: "t4", name: "Chart offset", initialValue: nil, renderer: OptionalToggleRenderer(renderer: SliderRenderer(range: 0 ... 10), defaultValueForNewElement: 1), store: InMemoryStore())
        let chartValues = TweakDefinition(id: "t5", name: "Chart values", initialValue: [1,2,3])
        let count = TweakDefinition(id: "t6", name: "Count", initialValue: 1, renderer: CustomRenderer(previewView: { Text(String($0)) }, tweakView: { Stepper("", value: $0) }), store: InMemoryStore())
        let resetAction = TweakAction(name: "Reset onboarding") {
            print("reset")
        }
        let restartAction = TweakAction(name: "Restart app") {
            print("restart")
        }
        
        let tweakRepo = TweakRepository.shared
        tweakRepo.add(tweak: numberOfItems, category: "Product Settings", section: "Feature Settings")
        tweakRepo.add(tweak: chartOffset, category: "Product Settings", section: "Feature Settings")
        tweakRepo.add(tweak: chartValues, category: "Product Settings", section: "Feature Settings")
        tweakRepo.add(tweak: name, category: "Product Settings", section: "Feature Settings")
        tweakRepo.add(tweak: enabled, category: "Product Settings", section: "Feature Settings")
        tweakRepo.add(tweak: flag, category: "Product Settings", section: "Feature Settings")
        tweakRepo.add(tweak: count, category: "Product Settings", section: "Feature Settings")
        tweakRepo.add(tweak: resetAction, category: "Product Settings", section: "Actions")
        tweakRepo.add(tweak: restartAction, category: "Product Settings", section: "Actions")
        if #available(iOS 14.0, *) {
            let color = TweakDefinition(id: "t8", name: "Background Color", initialValue: Color.purple)
            tweakRepo.add(tweak: color, category: "Product Settings", section: "Feature Settings")
        }
        
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

