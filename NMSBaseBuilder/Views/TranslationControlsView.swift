import SwiftUI

struct TranslationControlsView: View {

    let onMove: (Int, Float) -> Void
    
    @State private var stepSize: Float = 1.0

    var body: some View {
        VStack(spacing: 10) {

            Text("TRANSLATE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            
            Picker("Movement Step", selection: $stepSize) {
                Text("Fine")
                    .tag(Float(0.1))
                Text("Medium")
                    .tag(Float(1.0))
                Text("Coarse")
                    .tag(Float(5.0))
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                axisControls("X", axis: 0, color: .red)
                axisControls("Y", axis: 1, color: .green)
                axisControls("Z", axis: 2, color: .blue)
            }
        }
        .padding(12)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .fixedSize()
    }

    private func axisControls(
        _ label: String,
        axis: Int,
        color: Color
    ) -> some View {

        VStack(spacing: 6) {

            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Button {
                print("Translation button tapped: \(label)+")
                onMove(axis, stepSize)
            } label: {
                Image(systemName: "plus")
                    .frame(width: 38, height: 32)
            }

            Button {
                print("Translation button tapped: \(label)-")
                onMove(axis, -stepSize)
            } label: {
                Image(systemName: "minus")
                    .frame(width: 38, height: 32)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
    }
}
