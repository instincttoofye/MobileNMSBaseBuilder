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
    


    private(set) var project: BaseProject?

    var hasProject: Bool {
        project != nil
    }

    func loadProject(_ project: BaseProject) {
        self.project = project
    }
    
    func preparePositionUpdate(
        at index: Int,
        position: [Float]
    ) throws -> BasePart {

        guard position.count == 3,
              position.allSatisfy(\.isFinite) else {
            throw EditError.invalidPosition
        }

        guard let project,
              project.parts.indices.contains(index) else {
            throw EditError.invalidPartIndex
        }

        var part = project.parts[index]

        part.position = position

        return part
    }
    
    func commitPartUpdate(
        at index: Int,
        part: BasePart
    ) throws {

        guard var project,
              project.parts.indices.contains(index) else {
            throw EditError.invalidPartIndex
        }

        project.parts[index] = part

        self.project = project
    }
    
    func commitPartAddition(_ part: BasePart) throws -> Int {

        guard var project else {
            throw EditError.noProjectLoaded
        }

        let index = project.parts.count

        project.parts.append(part)

        self.project = project

        return index
    }
    
    func commitPartDeletion(at index: Int) throws {

        guard var project,
              project.parts.indices.contains(index) else {
            throw EditError.invalidPartIndex
        }

        project.parts.remove(at: index)

        self.project = project
    }
    
    func prepareRotationUpdate(
        at index: Int,
        angles: NMSEulerConverter.EulerAngles
    ) throws -> BasePart {

        guard angles.pitch.isFinite,
              angles.yaw.isFinite,
              angles.roll.isFinite else {
            throw EditError.invalidRotation
        }

        guard let project,
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

        return part
    }
}
