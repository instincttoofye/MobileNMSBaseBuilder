//
//  NMSPartCatalog.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/1/26.
//


//
//  NMSPartCatalog.swift
//  NMSBaseBuilder
//

import Foundation

enum NMSPartCatalog {

    static let parts: [NMSPartDefinition] = [
        NMSPartDefinition(
            objectID: "^PIPESHAPE",
            name: "Pipe Shape",
            category: "Shapes",
            subcategory: nil,
            modelCategory: nil,
            meshPath: nil
        ),
        NMSPartDefinition(
            objectID: "^CYLINDERSHAPE",
            name: "Cylinder Shape",
            category: "Shapes",
            subcategory: nil,
            modelCategory: nil,
            meshPath: nil
        ),
        NMSPartDefinition(
            objectID: "^C_WALL_Q_H",
            name: "Legacy Concrete Short Wall",
            category: "Structural",
            subcategory: nil,
            modelCategory: nil,
            meshPath: nil
        ),
        NMSPartDefinition(
            objectID: "^BUILDPAVINGTALL",
            name: "Tall Paving",
            category: "Structural",
            subcategory: nil,
            modelCategory: nil,
            meshPath: nil
        ),
        NMSPartDefinition(
            objectID: "^WALLLIGHTRED",
            name: "Red Wall Light",
            category: "Decoration",
            subcategory: nil,
            modelCategory: nil,
            meshPath: nil
        ),
        NMSPartDefinition(
            objectID: "^WALLLIGHTWHITE",
            name: "White Wall Light",
            category: "Decoration",
            subcategory: nil,
            modelCategory: nil,
            meshPath: nil
        )
    ]

    static var categories: [String] {
        Array(Set(parts.map(\.category))).sorted()
    }

    static func parts(in category: String) -> [NMSPartDefinition] {
        parts.filter { $0.category == category }
    }
}
