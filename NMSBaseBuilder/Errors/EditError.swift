//
//  EditError.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/1/26.
//
import Foundation

enum EditError: Error {
    case noProjectLoaded
    case invalidPartIndex
    case invalidPosition
    case invalidRotation
}
