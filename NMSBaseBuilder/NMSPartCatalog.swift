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
            category: .shapes
        ),

        NMSPartDefinition(
            objectID: "^CYLINDERSHAPE",
            name: "Cylinder Shape",
            category: .shapes
        ),

        NMSPartDefinition(
            objectID: "^C_WALL_Q_H",
            name: "Legacy Concrete Short Wall",
            category: .structural
        ),

        NMSPartDefinition(
            objectID: "^BUILDPAVINGTALL",
            name: "Tall Paving",
            category: .structural
        ),

        NMSPartDefinition(
            objectID: "^WALLLIGHTRED",
            name: "Red Wall Light",
            category: .decoration
        ),

        NMSPartDefinition(
            objectID: "^WALLLIGHTWHITE",
            name: "White Wall Light",
            category: .decoration
        )
    ]

    static func parts(
        in category: NMSPartCategory
    ) -> [NMSPartDefinition] {

        parts.filter { $0.category == category }
    }
}