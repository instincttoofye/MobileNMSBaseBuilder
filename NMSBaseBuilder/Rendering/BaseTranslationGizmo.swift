//
//  BaseTranslationGizmo.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/2/26.
//


import SceneKit
import UIKit

@MainActor
final class BaseTranslationGizmo {

    let rootNode = SCNNode()

    init() {
        rootNode.name = "TranslationGizmo"

        createAxis(
            name: "GizmoX",
            direction: SCNVector3(1, 0, 0),
            color: .systemRed
        )

        createAxis(
            name: "GizmoY",
            direction: SCNVector3(0, 1, 0),
            color: .systemGreen
        )

        createAxis(
            name: "GizmoZ",
            direction: SCNVector3(0, 0, 1),
            color: .systemBlue
        )
    }

    private func createAxis(
        name: String,
        direction: SCNVector3,
        color: UIColor
    ) {
        let shaft = SCNCylinder(
            radius: 0.035,
            height: 1.5
        )

        let tip = SCNCone(
            topRadius: 0,
            bottomRadius: 0.12,
            height: 0.3
        )

        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .constant

        shaft.materials = [material]
        tip.materials = [material]

        let axisNode = SCNNode()
        axisNode.name = name

        let shaftNode = SCNNode(geometry: shaft)
        shaftNode.position.y = 0.75

        let tipNode = SCNNode(geometry: tip)
        tipNode.position.y = 1.65

        axisNode.addChildNode(shaftNode)
        axisNode.addChildNode(tipNode)

        // Geometry is built along local +Y.
        // Rotate it to point along the requested world axis.

        if direction.x == 1 {
            axisNode.eulerAngles.z = -.pi / 2
        } else if direction.z == 1 {
            axisNode.eulerAngles.x = .pi / 2
        }

        rootNode.addChildNode(axisNode)
    }

    func attach(to node: SCNNode, in scene: SCNScene) {

        rootNode.removeFromParentNode()

        rootNode.simdTransform = matrix_identity_float4x4
        rootNode.simdPosition = node.simdWorldPosition

        scene.rootNode.addChildNode(rootNode)
    }

    func detach() {
        rootNode.removeFromParentNode()
    }
    
    func updatePosition(to node: SCNNode) {
        rootNode.simdPosition = node.simdWorldPosition
    }
}
