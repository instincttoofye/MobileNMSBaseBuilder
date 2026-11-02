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
}