//
//  BaseHistoryManager.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/1/26.
//


import Foundation
import BaseCore

@MainActor
@Observable
final class BaseHistoryManager {

    private var undoStack: [BaseProject] = []
    private var redoStack: [BaseProject] = []

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    var canRedo: Bool {
        !redoStack.isEmpty
    }

    func record(_ project: BaseProject) {
        undoStack.append(project)
        redoStack.removeAll()
    }

    func previousProject() -> BaseProject? {
        undoStack.last
    }

    func nextProject() -> BaseProject? {
        redoStack.last
    }

    func commitUndo(currentProject: BaseProject) {
        guard !undoStack.isEmpty else { return }

        undoStack.removeLast()
        redoStack.append(currentProject)
    }

    func commitRedo(currentProject: BaseProject) {
        guard !redoStack.isEmpty else { return }

        redoStack.removeLast()
        undoStack.append(currentProject)
    }

    func reset() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}