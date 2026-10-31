//
//  PartInspectorView.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//


import SwiftUI
import BaseCore

struct PartInspectorView: View {

    let part: BasePart
    let index: Int

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Text(part.objectID)
                    .font(.headline)

                Spacer()

                Text("#\(index)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Text("POSITION")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {

                coordinate("X", value: part.position[0])

                Spacer()

                coordinate("Y", value: part.position[1])

                Spacer()

                coordinate("Z", value: part.position[2])
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func coordinate(
        _ axis: String,
        value: Float
    ) -> some View {

        VStack(alignment: .leading, spacing: 4) {

            Text(axis)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value, format: .number.precision(.fractionLength(3)))
                .font(.system(.subheadline, design: .monospaced))
        }
    }
}