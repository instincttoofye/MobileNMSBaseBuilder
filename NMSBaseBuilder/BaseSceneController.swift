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
    
    private let projectEditor = BaseProjectEditor()

    var project: BaseProject? {
        projectEditor.project
    }
    private(set) var selectedNode: SCNNode?
    private let historyManager = BaseHistoryManager()
    
    var canUndo: Bool { historyManager.canUndo }
    var canRedo: Bool { historyManager.canRedo }
    
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
    private let renderer = BaseSceneRenderer()
    weak var sceneView: SCNView?

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

        guard let node = partNodes[index] else {
            throw PositionUpdateError.missingSceneNode
        }

        guard let previousProject = project else {
            throw ExportError.noProjectLoaded
        }

        let updatedPart = try projectEditor.preparePositionUpdate(
            at: index,
            position: position
        )

        let matrix = try NMSCoordinateConverter.createMatrix(
            from: updatedPart.transform
        )

        try projectEditor.commitPartUpdate(
            at: index,
            part: updatedPart
        )

        recordSnapshot(previousProject)

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
    
    func loadProject(_ newProject: BaseProject, resetHistory: Bool = true) throws {

        var newNodes: [(index: Int, node: SCNNode)] = []

        for (index, part) in newProject.parts.enumerated() {

            let node = try renderer.createNode(for: part)

            newNodes.append((index: index, node: node))
        }

        // Only replace the existing scene after every part succeeds.
        clearProjectNodes()

        projectEditor.loadProject(newProject)

        for entry in newNodes {

            nodePartIndices[entry.node] = entry.index
            partNodes[entry.index] = entry.node

            scene.rootNode.addChildNode(entry.node)
        }

        print("Loaded \(newProject.parts.count) NMS parts")
        
        if resetHistory {
            historyManager.reset()
        }
    }
    
    func updatePartRotation(
        at index: Int,
        angles: NMSEulerConverter.EulerAngles
    ) throws {

        guard let node = partNodes[index] else {
            throw PositionUpdateError.missingSceneNode
        }

        guard let previousProject = project else {
            throw ExportError.noProjectLoaded
        }

        let updatedPart = try projectEditor.prepareRotationUpdate(
            at: index,
            angles: angles
        )

        let matrix = try NMSCoordinateConverter.createMatrix(
            from: updatedPart.transform
        )

        try projectEditor.commitPartUpdate(
            at: index,
            part: updatedPart
        )

        recordSnapshot(previousProject)

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

        guard let previousProject = project else {
            throw ExportError.noProjectLoaded
        }

        // Prepare the SceneKit representation.
        let node = try renderer.createNode(for: part)
        // Commit the model change.
        let index = try projectEditor.commitPartAddition(part)

        // Preserve the previous project for Undo.
        recordSnapshot(previousProject)

        // Register the SceneKit node.
        nodePartIndices[node] = index
        partNodes[index] = node

        scene.rootNode.addChildNode(node)

        // Select the newly added component.
        selectNode(node)
    }
    
    func spawnPositionInFrontOfCamera(distance: Float = 5) -> [Float] {

        guard let camera = sceneView?.pointOfView else {
            return [0, 0, 0]
        }

        let localPosition = SCNVector3(0, 0, -distance)

        let worldPosition = camera.convertPosition(
            localPosition,
            to: nil
        )

        return [
            worldPosition.x,
            worldPosition.y,
            worldPosition.z
        ]
    }
    
    func deleteSelectedPart() throws {

        guard let previousProject = project else {
            throw ExportError.noProjectLoaded
        }

        guard let selectedNode,
              let index = nodePartIndices[selectedNode] else {
            return
        }

        // Commit the model deletion first.
        try projectEditor.commitPartDeletion(at: index)

        // Preserve the previous state for Undo.
        recordSnapshot(previousProject)

        // Remove the corresponding SceneKit node.
        selectedNode.removeFromParentNode()

        // Clear selection and highlighting.
        selectNode(nil)

        // Remove the deleted node from our mappings.
        nodePartIndices.removeValue(forKey: selectedNode)
        partNodes.removeValue(forKey: index)

        // Rebuild indices for the remaining nodes.
        var updatedNodePartIndices: [SCNNode: Int] = [:]
        var updatedPartNodes: [Int: SCNNode] = [:]

        for (oldIndex, node) in partNodes {

            let newIndex = oldIndex > index
                ? oldIndex - 1
                : oldIndex

            updatedNodePartIndices[node] = newIndex
            updatedPartNodes[newIndex] = node
        }

        nodePartIndices = updatedNodePartIndices
        partNodes = updatedPartNodes
    }
    
    private func recordSnapshot(_ snapshot: BaseProject) {
        historyManager.record(snapshot)
    }
    
    func undo() throws {
        guard let previousProject = historyManager.previousProject(),
              let currentProject = project else {
            return
        }

        try loadProject(previousProject, resetHistory: false)

        historyManager.commitUndo(currentProject: currentProject)
    }
    
    func redo() throws {
        guard let nextProject = historyManager.nextProject(),
              let currentProject = project else {
            return
        }

        try loadProject(nextProject, resetHistory: false)

        historyManager.commitRedo(currentProject: currentProject)
    }
}
