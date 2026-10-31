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
            
            Button("Test JSON Export") {

                do {
                    let data = try controller.exportProject()

                    print("Exported \(data.count) bytes")

                    if let json = String(
                        data: data,
                        encoding: .utf8
                    ) {
                        print(json)
                    }

                } catch {
                    print("Export failed: \(error)")
                }
            }

            BaseSceneView(controller: controller)
                .overlay(alignment: .bottom) {

                    if let part = controller.selectedPart,
                       let index = controller.selectedPartIndex {

                        PartInspectorView(
                            part: part,
                            index: index,
                            onPositionChange: { newPosition in

                                do {
                                    try controller.updatePartPosition(
                                        at: index,
                                        position: newPosition
                                    )
                                } catch {
                                    print("Failed to update position: \(error)")
                                }
                            }
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
