//
//  ContentView.swift
//  TweaksExample
//
//  Created by László Teveli on 2020. 06. 12..
//  Copyright © 2020. Laszlo Teveli. All rights reserved.
//

import SwiftUI
import Tweaks

struct ContentView: View {
    @State var showTweaks = false
    
    var body: some View {
        VStack {
            Text("Hello!")
            Button(action: { showTweaks = true }) {
                Text("Open Tweaks")
            }
        }
        .sheet(isPresented: $showTweaks) {
            TweaksView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
