//
//  ContentView.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import SwiftUI

struct ContentView: View {

    @State private var controller = BaseSceneController()

    var body: some View {

        VStack(spacing: 0) {

            Text("NMS Base Builder")
                .font(.title2)
                .bold()
                .padding()

            BaseSceneView(controller: controller)
                .overlay(alignment: .bottom) {

                    if let part = controller.selectedPart,
                       let index = controller.selectedPartIndex {

                        PartInspectorView(
                            part: part,
                            index: index
                        )
                        .padding()
                    }
                }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentView()
}
