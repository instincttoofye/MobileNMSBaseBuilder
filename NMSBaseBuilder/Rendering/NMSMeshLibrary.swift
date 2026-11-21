//
//  NMSMeshLibrary.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import Foundation
import SceneKit
import UIKit

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

    private lazy var catalogLookup: [String: NMSPartDefinition] = {
        Dictionary(
            uniqueKeysWithValues: NMSPartCatalog.parts.map {
                ($0.objectID, $0)
            }
        )
    }()

    func createNode(for objectID: String) -> SCNNode {
        
        print("Resolving mesh for: \(objectID)")
        print("Catalog entry exists: \(catalogLookup[objectID] != nil)")

        if meshRegistry[objectID] == nil,
           let part = catalogLookup[objectID],
           let meshPath = part.meshPath {

            let modelURL = URL(fileURLWithPath: meshPath)

            let assetName = modelURL
                .deletingPathExtension()
                .lastPathComponent

            let category = part.modelCategory
                ?? modelURL.deletingLastPathComponent().lastPathComponent
            
            print("Looking for: \(objectID)")
            print("Asset name: \(assetName)")
            print("Category: \(category)")
            print("Mesh path: \(meshPath)")

            // Preferred: preserve the original model directory.
            let directoryURL = Bundle.main.url(
                forResource: assetName,
                withExtension: "usdz",
                subdirectory: "ConvertedModels/\(category)"
            )

            // Compatibility with our existing flat USDZ assets.
            let flatURL = Bundle.main.url(
                forResource: assetName,
                withExtension: "usdz"
            )
            
            if directoryURL == nil {
                print("Directory lookup FAILED: \(category)/\(assetName).usdz")
            }

            if flatURL == nil {
                print("Flat lookup FAILED: \(assetName).usdz")
            }

            if let url = directoryURL ?? flatURL {

                do {
                    let scene = try SCNScene(
                        url: url,
                        options: nil
                    )

                    print("Loaded USDZ from: \(url.path)")

                    return cloneSceneContents(scene)

                } catch {
                    print(
                        "USDZ loading failed for \(objectID): \(error)"
                    )
                }
            }
        }

        // Original OBJ compatibility.
        if let assetName = meshRegistry[objectID],
           let scene = SCNScene(named: "\(assetName).obj") {

            return cloneSceneContents(scene)
        }

        print("No mesh available for \(objectID)")
        return createPlaceholder()
    }

    private func cloneSceneContents(
        _ scene: SCNScene
    ) -> SCNNode {

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
