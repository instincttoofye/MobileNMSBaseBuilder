import SwiftUI

struct TranslationControlsView: View {

    let onMove: (Int, Float) -> Void

    var body: some View {
        VStack(spacing: 10) {

            Text("TRANSLATE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                axisControls("X", axis: 0, color: .red)
                axisControls("Y", axis: 1, color: .green)
                axisControls("Z", axis: 2, color: .blue)
            }
        }
        .padding(12)
        .background(.black.opacity(0.85))
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
                onMove(axis, 1)
            } label: {
                Image(systemName: "plus")
                    .frame(width: 38, height: 32)
            }

            Button {
                print("Translation button tapped: \(label)-")
                onMove(axis, -1)
            } label: {
                Image(systemName: "minus")
                    .frame(width: 38, height: 32)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
    }
}
