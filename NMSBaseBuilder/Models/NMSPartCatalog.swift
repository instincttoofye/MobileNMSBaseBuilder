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

    static let parts: [NMSPartDefinition] = {
        guard let url = Bundle.main.url(
            forResource: "NMSParts",
            withExtension: "json"
        ) else {
            assertionFailure("NMSParts.json not found in app bundle")
            return []
        }

        do {
            let data = try Data(contentsOf: url)

            return try JSONDecoder().decode(
                [NMSPartDefinition].self,
                from: data
            )
        } catch {
            assertionFailure("Failed to load NMS catalog: \(error)")
            return []
        }
    }()

    static var categories: [String] {
        Array(Set(parts.map(\.category))).sorted()
    }

    static func parts(
        in category: String
    ) -> [NMSPartDefinition] {
        parts.filter { $0.category == category }
    }
}
