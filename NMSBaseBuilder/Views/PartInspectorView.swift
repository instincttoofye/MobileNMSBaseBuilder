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
    let onRotationChange: (NMSEulerConverter.EulerAngles) -> Void
    let onTranslation: (Int, Float) -> Void
    let onDelete: () -> Void

    @State private var xPosition: String = ""
    @State private var yPosition: String = ""
    @State private var zPosition: String = ""
    @State private var yawDegrees: String = ""
    @State private var pitchDegrees: String = ""
    @State private var rollDegrees: String = ""
    @State private var showingDeleteConfirmation: Bool = false
    @State private var isExpanded: Bool = false

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Header

            HStack {

                Text(part.objectID)
                    .font(.headline)

                Spacer()

                Text("#\(index)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(
                        systemName: isExpanded
                            ? "chevron.down"
                            : "chevron.up"
                    )
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // MARK: - Expanded Controls

            if isExpanded {

                Divider()

                ScrollView {

                    VStack(alignment: .leading, spacing: 12) {

                        // MARK: - Position

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

                        // MARK: - Translation

                        TranslationControlsView { axis, amount in
                            onTranslation(axis, amount)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        Divider()

                        // MARK: Rotation

                        Text("ROTATION")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {

                            rotationField(
                                "Pitch",
                                text: $pitchDegrees,
                                axis: 0
                            )

                            rotationField(
                                "Yaw",
                                text: $yawDegrees,
                                axis: 1
                            )

                            rotationField(
                                "Roll",
                                text: $rollDegrees,
                                axis: 2
                            )
                        }

                        // MARK: - Delete

                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label(
                                "Delete Part",
                                systemImage: "trash"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 240)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))

        // MARK: - Delete Confirmation

        .confirmationDialog(
            "Delete this part?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Part", role: .destructive) {
                onDelete()
            }

            Button("Cancel", role: .cancel) {}

        } message: {
            Text("This will remove the selected component from your base.")
        }

        // MARK: - State Synchronization

        .onAppear {
            resetPositionFields()
            resetRotationFields()
        }

        .onChange(of: index) { _, _ in
            resetPositionFields()
            resetRotationFields()
        }
        .onChange(of: part.position) { _, _ in
            resetPositionFields()
        }
        .onChange(of: part.up) { _, _ in
            resetRotationFields()
        }
        .onChange(of: part.at) { _, _ in
            resetRotationFields()
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
    
    private func resetRotationFields() {
        do {
            let angles = try NMSEulerConverter.extractEulerAngles(
                from: part.transform
            )

            let radiansToDegrees: Float = 180 / .pi

            pitchDegrees = String(angles.pitch * radiansToDegrees)
            yawDegrees = String(angles.yaw * radiansToDegrees)
            rollDegrees = String(angles.roll * radiansToDegrees)

        } catch {
            print("Failed to extract rotation: \(error)")
            pitchDegrees = ""
            yawDegrees = ""
            rollDegrees = ""
        }
    }
    
    private func updateRotation(
        axis: Int,
        text: String
    ) {
        guard let degrees = Float(text),
              degrees.isFinite else {
            resetRotationFields()
            return
        }

        do {
            var angles = try NMSEulerConverter.extractEulerAngles(
                from: part.transform
            )

            let radians = degrees * .pi / 180

            switch axis {
            case 0:
                angles.pitch = radians

            case 1:
                angles.yaw = radians

            case 2:
                angles.roll = radians

            default:
                return
            }

            onRotationChange(angles)

        } catch {
            print("Failed to update rotation: \(error)")
            resetRotationFields()
        }
    }
    
    private func rotationField(
        _ label: String,
        text: Binding<String>,
        axis: Int
    ) -> some View {

        VStack(alignment: .leading, spacing: 4) {
            Text("\(label) (°)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            TextField(label, text: text)
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    updateRotation(
                        axis: axis,
                        text: text.wrappedValue
                    )
                }
        }
        .frame(maxWidth: .infinity)
    }
}
