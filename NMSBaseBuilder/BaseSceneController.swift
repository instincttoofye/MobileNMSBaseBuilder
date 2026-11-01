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
@Observable
final class BaseSceneController {
    
    enum PositionUpdateError: Error {
        case invalidPosition
        case invalidPartIndex
        case missingSceneNode
    }
    
    enum ExportError: Error {
        case noProjectLoaded
    }

    let scene = SCNScene()
    
    private(set) var project: BaseProject?
    private(set) var selectedNode: SCNNode?
    
    var selectedPart: BasePart? {
        guard let selectedNode else {
            return nil
        }

        return part(for: selectedNode)
    }
    
    var selectedPartIndex: Int? {
        guard let selectedNode else {
            return nil
        }

        return nodePartIndices[selectedNode]
    }
    
    private var nodePartIndices: [SCNNode: Int] = [:]
    private var partNodes: [Int: SCNNode] = [:]
    private var originalEmissions: [ObjectIdentifier: Any] = [:]
    private let defaultColor = UIColor.systemTeal
    private let selectedColor = UIColor.systemOrange
    private let meshLibrary = NMSMeshLibrary()

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

            try loadProject(project)

        } catch {
            print("Failed to load LampPostA: \(error)")
        }
    }
    
    func selectNode(_ node: SCNNode?) {

        if let selectedNode {
            setHighlight(false, for: selectedNode)
        }

        selectedNode = node

        if let node {
            setHighlight(true, for: node)
        }
    }
    
    func part(for node: SCNNode) -> BasePart? {

        guard let index = nodePartIndices[node],
              let project,
              project.parts.indices.contains(index) else {
            return nil
        }

        return project.parts[index]
    }
    
    func updatePartPosition(
        at index: Int,
        position: [Float]
    ) throws {

        guard position.count == 3,
              position.allSatisfy(\.isFinite) else {
            throw PositionUpdateError.invalidPosition
        }

        guard var project,
              project.parts.indices.contains(index) else {
            throw PositionUpdateError.invalidPartIndex
        }

        guard let node = partNodes[index] else {
            throw PositionUpdateError.missingSceneNode
        }

        // Retrieve and modify the NMS component.
        var part = project.parts[index]
        part.position = position

        // Rebuild its transformation matrix.
        let transform = try part.transform

        let matrix = try NMSCoordinateConverter.createMatrix(
            from: transform
        )

       
        project.parts[index] = part
        self.project = project

        node.simdTransform = matrix
    }
    
    func exportProject() throws -> Data {

        guard let project else {
            throw ExportError.noProjectLoaded
        }

        let encoder = JSONEncoder()

        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]

        return try encoder.encode(project)
    }
    
    private func clearProjectNodes() {

        for node in partNodes.values {
            node.removeFromParentNode()
        }

        partNodes.removeAll()
        nodePartIndices.removeAll()

        selectedNode = nil
        
        originalEmissions.removeAll()
    }
    
    func loadProject(_ newProject: BaseProject) throws {

        var newNodes: [(index: Int, node: SCNNode)] = []

        for (index, part) in newProject.parts.enumerated() {

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

            newNodes.append((index: index, node: node))
        }

        // Only replace the existing scene after every part succeeds.
        clearProjectNodes()

        self.project = newProject

        for entry in newNodes {

            nodePartIndices[entry.node] = entry.index
            partNodes[entry.index] = entry.node

            scene.rootNode.addChildNode(entry.node)
        }

        print("Loaded \(newProject.parts.count) NMS parts")
    }
    
    func updatePartRotation(
        at index: Int,
        angles: NMSEulerConverter.EulerAngles
    ) throws {

        guard var project,
              project.parts.indices.contains(index) else {
            throw PositionUpdateError.invalidPartIndex
        }

        guard let node = partNodes[index] else {
            throw PositionUpdateError.missingSceneNode
        }

        // Retrieve the component we're modifying.
        var part = project.parts[index]

        // Extract its existing NMS transform.
        let originalTransform = try part.transform

        // Apply the requested Euler angles.
        let updatedTransform = NMSEulerConverter.applyEulerAngles(
            angles,
            to: originalTransform
        )

        // Build the updated SceneKit transformation matrix.
        let matrix = try NMSCoordinateConverter.createMatrix(
            from: updatedTransform
        )

        // Update the component's stored NMS vectors.
        part.updateTransform(updatedTransform)

        // Update our source of truth.
        project.parts[index] = part
        self.project = project

        // Synchronize SceneKit.
        node.simdTransform = matrix
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
    
    private func setHighlight(
        _ highlighted: Bool,
        for node: SCNNode
    ) {
        node.enumerateHierarchy { child, _ in
            guard let geometry = child.geometry else {
                return
            }

            for material in geometry.materials {

                let identifier = ObjectIdentifier(material)

                if highlighted {

                    if originalEmissions[identifier] == nil {
                        originalEmissions[identifier] =
                            material.emission.contents ?? UIColor.black
                    }

                    material.emission.contents = UIColor.systemOrange

                } else {

                    if let original = originalEmissions.removeValue(
                        forKey: identifier
                    ) {
                        material.emission.contents = original
                    }
                }
            }
        }
    }
    
    func addPart(_ part: BasePart) throws {
        guard var project else {
            throw ExportError.noProjectLoaded
        }

        let index = project.parts.count

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

        // Update our source of truth.
        project.parts.append(part)
        self.project = project

        // Register the new component.
        nodePartIndices[node] = index
        partNodes[index] = node

        scene.rootNode.addChildNode(node)

        // Automatically select the new component.
        selectNode(node)
    }
}
