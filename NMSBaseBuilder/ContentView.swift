//
//  ContentView.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        VStack(spacing: 0) {

            Text("NMS Base Builder")
                .font(.title2)
                .bold()
                .padding()

            BaseSceneView()
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    ContentView()
}
