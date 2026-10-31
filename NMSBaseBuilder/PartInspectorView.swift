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
    
    let onPositionChange: ([Float]) -> Void

    @State private var xPosition = ""

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

                VStack(alignment: .leading, spacing: 4) {

                    Text("X")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    TextField("X", text: $xPosition)
                        .keyboardType(.numbersAndPunctuation)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 95)
                        .onSubmit {
                            updateXPosition()
                        }
                }

                Spacer()

                coordinate("Y", value: part.position[1])

                Spacer()

                coordinate("Z", value: part.position[2])
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            xPosition = String(part.position[0])
        }
        .onChange(of: index) { _, _ in
            xPosition = String(part.position[0])
        }
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
    
    private func updateXPosition() {

        guard let newX = Float(xPosition),
              newX.isFinite else {
            xPosition = String(part.position[0])
            return
        }

        var newPosition = part.position

        newPosition[0] = newX

        onPositionChange(newPosition)
    }
}
