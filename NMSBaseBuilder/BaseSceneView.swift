//
//  BaseSceneView.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 10/31/26.
//

import SwiftUI
import SceneKit

struct BaseSceneView: View {

    @State private var controller = BaseSceneController()

    var body: some View {

        SceneView(
            scene: controller.scene,
            options: [
                .allowsCameraControl
            ]
        )
    }
}
