//
//  ContentView.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import SwiftUI

struct ContentView: View {

    @State private var controller = BaseSceneController()
    @State private var isExporting = false
    @State private var exportDocument: BaseProjectDocument?

    var body: some View {

        VStack(spacing: 0) {

            Text("NMS Base Builder")
                .font(.title2)
                .bold()
                .padding()
            
            Button("Export JSON") {
                do {
                    let data = try controller.exportProject()

                    exportDocument = BaseProjectDocument(data: data)
                    isExporting = true

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
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "NMSBase"
        ) { result in

            switch result {
            case .success(let url):
                print("Exported successfully: \(url)")

            case .failure(let error):
                print("Export failed: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
