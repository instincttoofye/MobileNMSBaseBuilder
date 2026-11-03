//
//  BaseSceneView.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import SwiftUI
import SceneKit
import simd

struct BaseSceneView: UIViewRepresentable {

    let controller: BaseSceneController

    func makeUIView(context: Context) -> SCNView {

        let view = SCNView()
        
        controller.sceneView = view

        view.scene = controller.scene
        view.allowsCameraControl = true
        view.backgroundColor = .black

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )

        view.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleGizmoPan(_:))
        )

        panGesture.delegate = context.coordinator

        view.addGestureRecognizer(panGesture)

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Nothing to update yet.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        let controller: BaseSceneController
        private var activeGizmoAxis: String?
        private var dragSession: GizmoDragSession?

        init(controller: BaseSceneController) {
            self.controller = controller
        }
        
        private func worldAxis(_ axis: String) -> SIMD3<Float>? {

            switch axis {
            case "X":
                return SIMD3<Float>(1, 0, 0)
            case "Y":
                return SIMD3<Float>(0, 1, 0)
            case "Z":
                return SIMD3<Float>(0, 0, 1)
            default:
                return nil
            }
        }
        
        private func projectedAxisMovement(
            axis: SIMD3<Float>,
            origin: SIMD3<Float>,
            screenTranslation: CGPoint,
            in view: SCNView
        ) -> Float? {

            let start = view.projectPoint(
                SCNVector3(origin.x, origin.y, origin.z)
            )

            let end = view.projectPoint(
                SCNVector3(
                    origin.x + axis.x,
                    origin.y + axis.y,
                    origin.z + axis.z
                )
            )

            let dx = Float(end.x - start.x)
            let dy = Float(end.y - start.y)

            let lengthSquared = dx * dx + dy * dy

            guard lengthSquared > 0.0001 else {
                return nil
            }

            let fingerX = Float(screenTranslation.x)
            let fingerY = Float(screenTranslation.y)

            return (fingerX * dx + fingerY * dy) / lengthSquared
        }
        
        private func gizmoAxis(for node: SCNNode) -> String? {

            var currentNode: SCNNode? = node

            while let current = currentNode {

                switch current.name {

                case "GizmoX":
                    return "X"

                case "GizmoY":
                    return "Y"

                case "GizmoZ":
                    return "Z"

                default:
                    currentNode = current.parent
                }
            }

            return nil
        }
        
        func gestureRecognizerShouldBegin(
            _ gestureRecognizer: UIGestureRecognizer
        ) -> Bool {

            guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let view = pan.view as? SCNView else {
                return true
            }

            let location = pan.location(in: view)
            let results = view.hitTest(location, options: nil)

            for result in results {
                if let axis = gizmoAxis(for: result.node) {
                    activeGizmoAxis = axis
                    return true
                }
            }

            activeGizmoAxis = nil
            return false
        }
        
        @objc func handleGizmoPan(_ gesture: UIPanGestureRecognizer) {

            guard let view = gesture.view as? SCNView else {
                return
            }

            switch gesture.state {

            case .began:

                guard let axisName = activeGizmoAxis,
                      let axis = worldAxis(axisName),
                      let node = controller.selectedNode,
                      let index = controller.selectedPartIndex,
                      let part = controller.selectedPart,
                      part.position.count == 3 else {
                    return
                }

                dragSession = GizmoDragSession(
                    node: node,
                    partIndex: index,
                    axis: axis,
                    startPosition: SIMD3<Float>(
                        part.position[0],
                        part.position[1],
                        part.position[2]
                    ),
                    startTransform: node.simdTransform
                )

            case .changed:

                guard let session = dragSession else {
                    return
                }

                guard controller.selectedNode === session.node,
                      controller.selectedPartIndex == session.partIndex else {
                    session.node.simdTransform = session.startTransform
                    dragSession = nil
                    return
                }

                let translation = gesture.translation(in: view)

                guard let distance = projectedAxisMovement(
                    axis: session.axis,
                    origin: session.startPosition,
                    screenTranslation: translation,
                    in: view
                ) else {
                    return
                }

                let newPosition = session.startPosition + session.axis * distance

                controller.previewPartPosition([
                    newPosition.x,
                    newPosition.y,
                    newPosition.z
                ])

            case .ended:

                defer {
                    dragSession = nil
                    activeGizmoAxis = nil
                }

                guard let session = dragSession else {
                    return
                }

                guard controller.selectedNode === session.node,
                      controller.selectedPartIndex == session.partIndex else {
                    session.node.simdTransform = session.startTransform
                    return
                }

                let finalPosition = session.node.simdPosition

                guard simd_length(finalPosition - session.startPosition) >= 0.00001 else {
                    controller.cancelPartPositionPreview()
                    return
                }

                do {
                    try controller.updatePartPosition(
                        at: session.partIndex,
                        position: [
                            finalPosition.x,
                            finalPosition.y,
                            finalPosition.z
                        ]
                    )
                } catch {
                    print("Failed to commit gizmo drag: \(error)")
                    controller.cancelPartPositionPreview()
                }
            case .cancelled, .failed:

                if let session = dragSession {
                    session.node.simdTransform = session.startTransform
                    controller.cancelPartPositionPreview()
                }

                dragSession = nil
                activeGizmoAxis = nil

            default:
                break
            }
        }
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {

            guard let view = gesture.view as? SCNView else {
                return
            }

            let location = gesture.location(in: view)

            let results = view.hitTest(
                location,
                options: nil
            )

            // MARK: - Gizmo Hit Detection

            for result in results {

                if let axis = gizmoAxis(for: result.node) {

                    print("Gizmo\(axis) tapped")

                    return
                }
            }

            // MARK: - Component Selection

            guard let hitNode = results.first?.node,
                  let componentNode = controller.componentNode(for: hitNode) else {

                controller.selectNode(nil)
                return
            }

            controller.selectNode(componentNode)
        }
    }
}
