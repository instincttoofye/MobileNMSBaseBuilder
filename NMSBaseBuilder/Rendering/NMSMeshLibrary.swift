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
        
        let startTime = CFAbsoluteTimeGetCurrent()

        defer {
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime

            print(
                "MESH PROFILE: \(objectID) — \(String(format: "%.2f", elapsed * 1000)) ms"
            )
        }
        

        if let part = catalogLookup[objectID],
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

                    let meshNode = cloneSceneContents(scene)

                    // Correct USDZ orientation for SceneKit.
                    meshNode.eulerAngles.x = -.pi / 2

                    return meshNode

                } catch {
                    print(
                        "USDZ loading failed for \(objectID): \(error)"
                    )
                }
            }
            
            let expectedURL = Bundle.main.bundleURL
                .appendingPathComponent("ConvertedModels")
                .appendingPathComponent(category)
                .appendingPathComponent("\(assetName).usdz")

            print("Expected path: \(expectedURL.path)")
            print(
                "File exists:",
                FileManager.default.fileExists(atPath: expectedURL.path)
            )
        }

        // Original OBJ compatibility.
        if let assetName = meshRegistry[objectID],
           let scene = SCNScene(named: "\(assetName).obj") {
            /*if objectID == "^C_WALL_Q_H" {
             print("=== ORIGINAL OBJ NODE HIERARCHY ===")
             inspectNode(scene.rootNode)
             }*/
            
          /*  let meshNode = cloneSceneContents(scene)
            
            if objectID == "^C_WALL_Q_H" ||
                objectID == "^CYLINDERSHAPE" {
                meshNode.eulerAngles.x = -.pi / 2
            }
            
            return meshNode*/
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
    
    private func inspectNode(
        _ node: SCNNode,
        depth: Int = 0
    ) {
        let indent = String(repeating: "  ", count: depth)

        print("\(indent)Node: \(node.name ?? "unnamed")")
        print("\(indent)Position: \(node.position)")
        print("\(indent)Rotation: \(node.eulerAngles)")
        print("\(indent)Scale: \(node.scale)")
        print("\(indent)Bounding box: \(node.boundingBox)")

        for child in node.childNodes {
            inspectNode(child, depth: depth + 1)
        }
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
