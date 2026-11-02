//
//  NMSPartDefinition.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/1/26.
//

//
//  NMSPartDefinition.swift
//  NMSBaseBuilder
//

import Foundation

enum NMSPartCategory: String, CaseIterable, Identifiable {
    case structural = "Structural"
    case decoration = "Decoration"
    case technology = "Technology"
    case shapes = "Shapes"

    var id: String { rawValue }
}

struct NMSPartDefinition: Identifiable {
    let objectID: String
    let name: String
    let category: NMSPartCategory

    var id: String { objectID }
}
