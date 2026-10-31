//
//  BaseSceneView.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import SwiftUI
import SceneKit

struct BaseSceneView: View {

    var body: some View {
        SceneView(
            scene: createScene(),
            options: [.allowsCameraControl, .autoenablesDefaultLighting]
        )
    }

    private func createScene() -> SCNScene {

        let scene = SCNScene()

        // Cube
        let cube = SCNBox(
            width: 1,
            height: 1,
            length: 1,
            chamferRadius: 0
        )

        let cubeNode = SCNNode(geometry: cube)

        cubeNode.position = SCNVector3(0, 0, 0)

        scene.rootNode.addChildNode(cubeNode)

        // Camera
        let camera = SCNCamera()

        let cameraNode = SCNNode()
        cameraNode.camera = camera

        cameraNode.position = SCNVector3(3, 3, 6)

        // Camera -> Cube
        cameraNode.look(
            at: SCNVector3(0, 0, 0)
        )

        scene.rootNode.addChildNode(cameraNode)

        return scene
    }
}
