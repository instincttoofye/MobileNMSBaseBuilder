//
//  NMSPartBrowserView.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/1/26.
//


//
//  NMSPartBrowserView.swift
//  NMSBaseBuilder
//

import SwiftUI

struct NMSPartBrowserView: View {

    @Environment(\.dismiss) private var dismiss

    let onSelectPart: (NMSPartDefinition) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(NMSPartCategory.allCases) { category in

                    let parts = NMSPartCatalog.parts(in: category)

                    if !parts.isEmpty {
                        Section(category.rawValue) {

                            ForEach(parts) { part in
                                Button {
                                    onSelectPart(part)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(part.name)

                                        Spacer()

                                        Image(systemName: "plus.circle")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Building Part")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}