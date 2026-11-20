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
    
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(NMSPartCatalog.categories, id: \.self) { category in

                    let parts = NMSPartCatalog.parts(in: category).filter {
                        searchText.isEmpty ||
                        $0.name.localizedCaseInsensitiveContains(searchText) ||
                        $0.objectID.localizedCaseInsensitiveContains(searchText)
                    }

                    if !parts.isEmpty {
                        Section(category) {

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
            .searchable(
                text: $searchText,
                prompt: "Search building parts"
            )
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
