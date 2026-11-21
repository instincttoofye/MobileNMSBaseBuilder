//
//  SceneRenderProfiler.swift
//  NMSBaseBuilder
//
//  Created by Zach Baron on 11/21/26.
//



import Foundation

final class SceneRenderProfiler: @unchecked Sendable {

    static let shared = SceneRenderProfiler()

    private let lock = NSLock()

    private var importFinishedAt: CFAbsoluteTime?
    private var pendingPartCount: Int?

    private init() {}

    func markImportFinished(partCount: Int) {
        lock.lock()
        defer { lock.unlock() }

        importFinishedAt = CFAbsoluteTimeGetCurrent()
        pendingPartCount = partCount
    }

    func markFrameRendered() {
        let now = CFAbsoluteTimeGetCurrent()

        lock.lock()

        guard let start = importFinishedAt,
              let count = pendingPartCount else {
            lock.unlock()
            return
        }

        importFinishedAt = nil
        pendingPartCount = nil

        lock.unlock()

        let elapsed = now - start

        print("""
        === SCENEKIT RENDER PROFILE ===
        Parts: \(count)
        Import-to-render callback: \(String(format: "%.3f", elapsed)) s
        ===============================
        """)
    }
}
