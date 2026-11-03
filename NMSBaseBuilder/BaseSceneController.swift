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

    let scene = SCNScene()
    
    private let projectEditor = BaseProjectEditor()
    private let gizmo = BaseTranslationGizmo()

    var project: BaseProject? {
        projectEditor.project
    }
    private let selectionManager = BaseSelectionManager()

    var selectedNode: SCNNode? {
        selectionManager.selectedNode
    }
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
        
        return renderer.index(for: selectedNode)
    }

    private let renderer = BaseSceneRenderer()
    private let environment = BaseSceneEnvironment()
    weak var sceneView: SCNView?

    init() {
        environment.setup(in: scene)
        loadLampPost()
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
        gizmo.detach()
        
        selectionManager.selectNode(node)
        
        if let node {
            gizmo.attach(to: node, in: scene)
        }
    }
    
    func part(for node: SCNNode) -> BasePart? {

        guard let index = renderer.index(for: node),
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

        guard let node = renderer.node(at: index) else {
            throw SceneEditingError.missingSceneNode
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
        
        if node === selectedNode {
            gizmo.updatePosition(to: node)
        }
    }
    
    func previewPartPosition(_ position: [Float]) {

        guard let selectedNode,
              position.count == 3,
              position.allSatisfy(\.isFinite) else {
            return
        }

        selectedNode.simdPosition = SIMD3<Float>(
            position[0],
            position[1],
            position[2]
        )

        gizmo.updatePosition(to: selectedNode)
    }

    func cancelPartPositionPreview() {

        guard let selectedNode,
              let selectedPart else {
            return
        }

        do {
            let matrix = try NMSCoordinateConverter.createMatrix(
                from: selectedPart.transform
            )

            selectedNode.simdTransform = matrix

            gizmo.updatePosition(to: selectedNode)

        } catch {
            print("Failed to restore drag preview: \(error)")
        }
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
        gizmo.detach()
        selectionManager.reset()
        renderer.clearNodes()
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

            renderer.register(entry.node, at: entry.index)

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

        guard let node = renderer.node(at: index) else {
            throw SceneEditingError.missingSceneNode
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
        renderer.componentNode(for: hitNode)
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

        renderer.register(node, at: index)

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
              let index = renderer.index(for: selectedNode) else {
            return
        }

        // Commit model deletion.
        try projectEditor.commitPartDeletion(at: index)

        // Preserve Undo history.
        recordSnapshot(previousProject)

        // Restore the selected node's original material appearance.
        selectNode(nil)

        // Remove the node and update all remaining indices.
        renderer.removeNode(at: index)
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
