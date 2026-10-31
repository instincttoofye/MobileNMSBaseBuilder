//
//  NMSMeshLibrary.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import Foundation
import SceneKit

@MainActor
final class NMSMeshLibrary {

    private let meshRegistry: [String: String] = [
        "^PIPESHAPE": "PipeShape"
    ]

    func createNode(for objectID: String) -> SCNNode {

        guard let assetName = meshRegistry[objectID] else {
            return createPlaceholder()
        }

        guard let scene = SCNScene(named: "\(assetName).obj") else {
            print("Mesh not found: \(assetName)")
            return createPlaceholder()
        }

        let meshNode = SCNNode()

        for child in scene.rootNode.childNodes {
            meshNode.addChildNode(child.clone())
        }

        return meshNode
    }

    private func createPlaceholder() -> SCNNode {

        let geometry = SCNBox(
            width: 0.5,
            height: 0.5,
            length: 0.5,
            chamferRadius: 0
        )

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemTeal

        geometry.materials = [material]

        return SCNNode(geometry: geometry)
    }
}
