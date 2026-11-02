//
//  BaseSceneEnvironment.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/1/26.
//


import SceneKit
import UIKit

@MainActor
final class BaseSceneEnvironment {

    func setup(in scene: SCNScene) {
        setupCamera(in: scene)
        setupLighting(in: scene)
    }

    private func setupCamera(in scene: SCNScene) {

        let cameraNode = SCNNode()

        cameraNode.name = "MainCamera"
        cameraNode.camera = SCNCamera()

        cameraNode.position = SCNVector3(10, 10, 20)
        cameraNode.look(at: SCNVector3(0, 3, 0))

        scene.rootNode.addChildNode(cameraNode)
    }

    private func setupLighting(in scene: SCNScene) {

        let lightNode = SCNNode()

        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(5, 15, 10)

        scene.rootNode.addChildNode(lightNode)

        let ambientNode = SCNNode()

        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        ambientNode.light?.color = UIColor(
            white: 0.4,
            alpha: 1
        )

        scene.rootNode.addChildNode(ambientNode)
    }
}