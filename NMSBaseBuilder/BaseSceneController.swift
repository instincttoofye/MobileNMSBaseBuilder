//
//  BaseSceneController.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import Foundation
import SceneKit
import BaseCore
import simd

@MainActor
final class BaseSceneController {

    let scene = SCNScene()
    
    private(set) var selectedNode: SCNNode?
    private let defaultColor = UIColor.systemTeal
    private let selectedColor = UIColor.systemOrange

    init() {
        setupCamera()
        setupLighting()
        loadLampPost()
    }

    private func setupCamera() {

        let cameraNode = SCNNode()
        cameraNode.name = "MainCamera"
        cameraNode.camera = SCNCamera()

        cameraNode.position = SCNVector3(10, 10, 20)
        cameraNode.look(at: SCNVector3(0, 3, 0))

        scene.rootNode.addChildNode(cameraNode)
    }

    private func setupLighting() {

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

    private func loadLampPost() {

        guard let url = Bundle.main.url(
            forResource: "LampPostA",
            withExtension: "json"
        ) else {
            print("Could not find LampPostA.json")
            return
        }

        do {

            let data = try Data(contentsOf: url)

            let project = try JSONDecoder().decode(
                BaseProject.self,
                from: data
            )

            print("Loaded \(project.parts.count) NMS parts")

            for part in project.parts {

                let transform = try part.transform

                let matrix = try NMSCoordinateConverter.createMatrix(
                    from: transform
                )

                let geometry = SCNBox(
                    width: 0.5,
                    height: 0.5,
                    length: 0.5,
                    chamferRadius: 0
                )

                let material = SCNMaterial()
                material.diffuse.contents = defaultColor

                geometry.materials = [material]

                let node = SCNNode(geometry: geometry)

                node.name = part.objectID

                node.simdTransform = matrix

                scene.rootNode.addChildNode(node)
            }

        } catch {
            print("Failed to load LampPostA: \(error)")
        }
    }
    
    func selectedNode(_ node: SCNNode) {
        if let previousNode = selectedNode {
            previousNode.geometry?.firstMaterial?.diffuse.contents = defaultColor
        }
        
        selectedNode = node
        node.geometry?.firstMaterial?.diffuse.contents = selectedColor
        
        print("Selected: \(node.name ?? "Unknown")")
        print("Position: \(node.position)")
    }
}
