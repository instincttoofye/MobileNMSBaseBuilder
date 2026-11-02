//
//  BaseProjectEditor.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/1/26.
//


import Foundation
import BaseCore

@MainActor
@Observable
final class BaseProjectEditor {
    
    enum EditError: Error {
        case noProjectLoaded
        case invalidPartIndex
        case invalidPosition
    }

    private(set) var project: BaseProject?

    var hasProject: Bool {
        project != nil
    }

    func loadProject(_ project: BaseProject) {
        self.project = project
    }
    
    func updatePartPosition(
        at index: Int,
        position: [Float]
    ) throws {

        guard position.count == 3,
              position.allSatisfy(\.isFinite) else {
            throw EditError.invalidPosition
        }

        guard var project,
              project.parts.indices.contains(index) else {
            throw EditError.invalidPartIndex
        }

        project.parts[index].position = position

        self.project = project
    }
    
    func updatePartRotation(
        at index: Int,
        angles: NMSEulerConverter.EulerAngles
    ) throws {

        guard var project,
              project.parts.indices.contains(index) else {
            throw EditError.invalidPartIndex
        }

        var part = project.parts[index]

        let originalTransform = try part.transform

        let updatedTransform = NMSEulerConverter.applyEulerAngles(
            angles,
            to: originalTransform
        )

        part.updateTransform(updatedTransform)

        project.parts[index] = part
        self.project = project
    }
}
