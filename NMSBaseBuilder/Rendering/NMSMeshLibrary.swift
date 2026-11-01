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
        "^PIPESHAPE": "PipeShape",
        "^WALLLIGHTRED": "WallLightRed",
        "^CYLINDERSHAPE": "CylinderShape",
        "^BUILDPAVINGTALL": "BuildPavingTall",
        "^C_WALL_Q_H": "LegacyConcreteShortWall",
        "^WALLLIGHTWHITE": "WallLightWhite"
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
            let instance = child.clone()

            instance.enumerateHierarchy { node, _ in
                guard let geometry = node.geometry else {
                    return
                }

                let uniqueGeometry = geometry.copy() as! SCNGeometry

                uniqueGeometry.materials = geometry.materials.map {
                    $0.copy() as! SCNMaterial
                }

                node.geometry = uniqueGeometry
            }

            meshNode.addChildNode(instance)
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
