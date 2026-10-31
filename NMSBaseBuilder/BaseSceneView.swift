//
//  BaseSceneView.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import SwiftUI
import SceneKit

struct BaseSceneView: UIViewRepresentable {

    let controller: BaseSceneController

    func makeUIView(context: Context) -> SCNView {

        let view = SCNView()

        view.scene = controller.scene
        view.allowsCameraControl = true
        view.backgroundColor = .white

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )

        view.addGestureRecognizer(tapGesture)

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Nothing to update yet.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    @MainActor
    final class Coordinator: NSObject {

        let controller: BaseSceneController

        init(controller: BaseSceneController) {
            self.controller = controller
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {

            guard let view = gesture.view as? SCNView else {
                return
            }

            let location = gesture.location(in: view)

            let results = view.hitTest(
                location,
                options: nil
            )

            guard let node = results.first?.node else {
                return
            }

            controller.selectedNode(node)
        }
    }
}
