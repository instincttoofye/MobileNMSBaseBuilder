//
//  BaseSceneRenderer.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/1/26.
//


import Foundation
import SceneKit
import BaseCore

@MainActor
final class BaseSceneRenderer {

    private let meshLibrary = NMSMeshLibrary()
    private var nodePartIndices: [SCNNode: Int] = [:]
    private var partNodes: [Int: SCNNode] = [:]

    func createNode(for part: BasePart) throws -> SCNNode {

        let transform = try part.transform

        let matrix = try NMSCoordinateConverter.createMatrix(
            from: transform
        )

        let node = SCNNode()

        node.name = part.objectID
        node.simdTransform = matrix

        let meshNode = meshLibrary.createNode(
            for: part.objectID
        )

        node.addChildNode(meshNode)

        return node
    }
    
    func node(at index: Int) -> SCNNode? {
        partNodes[index]
    }

    func index(for node: SCNNode) -> Int? {
        nodePartIndices[node]
    }

    func register(_ node: SCNNode, at index: Int) {
        nodePartIndices[node] = index
        partNodes[index] = node
    }

    func componentNode(for hitNode: SCNNode) -> SCNNode? {
        var currentNode: SCNNode? = hitNode

        while let node = currentNode {
            if nodePartIndices[node] != nil {
                return node
            }

            currentNode = node.parent
        }

        return nil
    }

    func clearNodes() {
        for node in partNodes.values {
            node.removeFromParentNode()
        }

        partNodes.removeAll()
        nodePartIndices.removeAll()
    }

    func removeNode(at index: Int) {
        guard let node = partNodes.removeValue(forKey: index) else {
            return
        }

        nodePartIndices.removeValue(forKey: node)
        node.removeFromParentNode()

        // Reindex remaining components.
        var updatedPartNodes: [Int: SCNNode] = [:]
        var updatedNodePartIndices: [SCNNode: Int] = [:]

        for (oldIndex, remainingNode) in partNodes {
            let newIndex = oldIndex > index
                ? oldIndex - 1
                : oldIndex

            updatedPartNodes[newIndex] = remainingNode
            updatedNodePartIndices[remainingNode] = newIndex
        }

        partNodes = updatedPartNodes
        nodePartIndices = updatedNodePartIndices
    }
}
