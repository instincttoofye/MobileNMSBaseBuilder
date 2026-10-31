//
//  ContentView.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import SwiftUI
import BaseCore

struct ContentView: View {

    @State private var controller = BaseSceneController()
    @State private var isExporting = false
    @State private var exportDocument: BaseProjectDocument?
    @State private var isImporting: Bool = false

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
            
            
            Button("Import JSON") {
                isImporting = true
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
                            },
                            onRotationChange: { angles in
                                do {
                                    try controller.updatePartRotation(
                                        at: index,
                                        angles: angles
                                    )
                                } catch {
                                    print("Rotation update failed: \(error)")
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
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in

            switch result {

            case .success(let urls):
                guard let url = urls.first else {
                    return
                }

                let hasAccess = url.startAccessingSecurityScopedResource()

                defer {
                    if hasAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                do {
                    let data = try Data(contentsOf: url)

                    let project = try JSONDecoder().decode(
                        BaseProject.self,
                        from: data
                    )

                    try controller.loadProject(project)

                    print("Imported: \(url.lastPathComponent)")

                } catch {
                    print("Failed to import project: \(error)")
                }

            case .failure(let error):
                print("Import failed: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
