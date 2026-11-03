//
//  GizmoDragSession.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/2/26.
//


import SceneKit
import simd

@MainActor
struct GizmoDragSession {

    let node: SCNNode

    let partIndex: Int

    let axis: SIMD3<Float>

    let startPosition: SIMD3<Float>

    let startTransform: simd_float4x4
}