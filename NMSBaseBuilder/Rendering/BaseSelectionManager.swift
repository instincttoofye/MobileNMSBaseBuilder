//
//  BaseSelectionManager.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/1/26.
//


import Foundation
import SceneKit
import UIKit

@MainActor
@Observable
final class BaseSelectionManager {

    private(set) var selectedNode: SCNNode?

    private var originalEmissions: [ObjectIdentifier: Any] = [:]

    func selectNode(_ node: SCNNode?) {

        if let selectedNode {
            setHighlight(false, for: selectedNode)
        }

        selectedNode = node

        if let node {
            setHighlight(true, for: node)
        }
    }

    func clearSelection() {
        selectNode(nil)
    }

    func reset() {
        selectedNode = nil
        originalEmissions.removeAll()
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
}