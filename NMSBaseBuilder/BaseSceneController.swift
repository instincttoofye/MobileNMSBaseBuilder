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
    private let defaultColor = UIColor.systemTeal
    private let selectedColor = UIColor.systemOrange

    init() {
        setupCamera()
        setupLighting()
        loadLampPost()

        do {
            try updatePartPosition(
                at: 5,
                position: [3, 2.9936051, 0]
            )

            print("Updated part position successfully")
            print("New position: \(project?.parts[5].position ?? [])")
        } catch {
            print("Failed to update position: \(error)")
        }
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
            
            self.project = project

            print("Loaded \(project.parts.count) NMS parts")

            for (index, part) in project.parts.enumerated() {

                let transform = try part.transform

                let matrix = try NMSCoordinateConverter.createMatrix(
                    from: transform
                )

                let geometry = SCNBox(
                    width: 0.5,
                    height: 0.5,
                    length: 0.5,
                    chamferRadius: 0
                )

                let material = SCNMaterial()
                material.diffuse.contents = defaultColor

                geometry.materials = [material]

                let node = SCNNode(geometry: geometry)

                node.name = part.objectID

                nodePartIndices[node] = index

                node.simdTransform = matrix

                scene.rootNode.addChildNode(node)
            }

        } catch {
            print("Failed to load LampPostA: \(error)")
        }
    }
    
    func selectNode(_ node: SCNNode) {
        if let previousNode = selectedNode {
            previousNode.geometry?.firstMaterial?.diffuse.contents = defaultColor
        }
        
        selectedNode = node
        node.geometry?.firstMaterial?.diffuse.contents = selectedColor
        
        print("Selected: \(node.name ?? "Unknown")")
        print("Position: \(node.position)")
        
        if let part = part(for: node),
           let index = nodePartIndices[node] {

            print("Part index: \(index)")
            print("ObjectID: \(part.objectID)")
            print("NMS Position: \(part.position)")
            print("NMS Up: \(part.up)")
            print("NMS At: \(part.at)")
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
        guard position.count == 3 else {
            throw PositionUpdateError.invalidPosition
        }
        
        guard var project, project.parts.indices.contains(index) else {
            throw PositionUpdateError.invalidPartIndex
        }
        
        var part = project.parts[index]
        
        part.position = position
        
        project.parts[index] = part
        
        self.project = project
    }
}
