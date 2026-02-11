//
//  ContentView.swift
//  HelloGit
//
//  Created by Jon Mell on 10/02/2026.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: GameScene(size: geometry.size))
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
