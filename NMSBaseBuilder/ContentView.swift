//
//  ContentView.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import SwiftUI
import BaseCore

struct ContentView: View {

    private let project = BaseProject(
        type: .base,
        parts: [],
        baseVersion: 8
    )

    var body: some View {
        VStack(spacing: 20) {

            Text("NMS Base Builder")
                .font(.largeTitle)
                .bold()

            Text("BaseCore Connected!")
                .foregroundStyle(.green)

            Text("Base Version: \(project.baseVersion)")

            Text("Building Parts: \(project.parts.count)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
