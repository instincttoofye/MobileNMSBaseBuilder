//
//  ProjectLoadError.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/21/26.
//
import Foundation

enum ProjectLoadError: LocalizedError {
    case alreadyLoading

    var errorDescription: String? {
        switch self {
        case .alreadyLoading:
            return "A project is already loading."
        }
    }
}
