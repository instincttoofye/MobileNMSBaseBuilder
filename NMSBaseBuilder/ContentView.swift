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
    @State private var isExporting: Bool = false
    @State private var exportDocument: BaseProjectDocument?
    @State private var isImporting: Bool = false
    @State private var isShowingPartBrowser: Bool = false

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
            
            Button("Add Part") {
                isShowingPartBrowser = true
            }
            
            HStack(spacing: 16) {

                Button {
                    do {
                        try controller.undo()
                    } catch {
                        print("Undo failed: \(error)")
                    }
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!controller.canUndo)

                Button {
                    do {
                        try controller.redo()
                    } catch {
                        print("Redo failed: \(error)")
                    }
                } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!controller.canRedo)
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
                            },
                            onDelete: {
                                do {
                                    try controller.deleteSelectedPart()
                                    print("part deleted")
                                } catch {
                                    print("Failed to delete part: \(error)")
                                }
                            }
                        )
                        .padding()
                    }
                }
        }
        .sheet(isPresented: $isShowingPartBrowser) {
            NMSPartBrowserView { definition in

                let part = BasePart(
                    objectID: definition.objectID,
                    position: controller.spawnPositionInFrontOfCamera(),
                    up: [0, 1, 0],
                    at: [0, 0, 1],
                    timestamp: 0,
                    userData: 0
                )

                do {
                    try controller.addPart(part)
                    print("Added: \(definition.name)")
                } catch {
                    print("Failed to add part: \(error)")
                }
            }
            .presentationDetents([.height(300), .medium])
            .presentationDragIndicator(.visible)
        }
        .background(Color(.black))
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
