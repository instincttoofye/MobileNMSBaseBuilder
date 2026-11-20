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

struct NMSPartDefinition: Codable, Identifiable {
    let objectID: String
    let name: String
    let category: String
    let subcategory: String?
    let modelCategory: String?
    let meshPath: String?

    var id: String { objectID }
}
