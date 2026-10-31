//
//  BaseProjectDocument.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//


import SwiftUI
import UniformTypeIdentifiers

struct BaseProjectDocument: FileDocument {

    static var readableContentTypes: [UTType] {
        [.json]
    }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {

        FileWrapper(regularFileWithContents: data)
    }
}