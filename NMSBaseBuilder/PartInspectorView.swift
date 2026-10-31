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
    @State private var yPosition = ""
    @State private var zPosition = ""

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

            HStack(spacing: 12) {

                coordinateField(
                    "X",
                    text: $xPosition,
                    axis: 0
                )

                coordinateField(
                    "Y",
                    text: $yPosition,
                    axis: 1
                )

                coordinateField(
                    "Z",
                    text: $zPosition,
                    axis: 2
                )
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            resetPositionFields()
        }
        .onChange(of: index) { _, _ in
            resetPositionFields()
        }
        .onChange(of: part.position) { _, _ in
            resetPositionFields()
        }
    }

    private func coordinateField(
        _ label: String,
        text: Binding<String>,
        axis: Int
    ) -> some View {

        VStack(alignment: .leading, spacing: 4) {

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            TextField(label, text: text)
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    updatePosition(
                        axis: axis,
                        text: text.wrappedValue
                    )
                }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func updatePosition(
        axis: Int,
        text: String
    ) {

        guard let newValue = Float(text),
              newValue.isFinite else {

            resetPositionFields()
            return
        }

        var newPosition = part.position

        newPosition[axis] = newValue

        onPositionChange(newPosition)
    }
    
    private func resetPositionFields() {

        xPosition = String(part.position[0])
        yPosition = String(part.position[1])
        zPosition = String(part.position[2])
    }
}
