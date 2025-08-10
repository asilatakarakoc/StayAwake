//
//  StayAwakeApp.swift
//  StayAwake
//
//  Created by Asil Ata Karakoç on 10.08.2025.
//

import SwiftUI
import AppKit
import IOKit.pwr_mgt

@MainActor
final class SleepKeeper: ObservableObject {
    static let shared = SleepKeeper()

    @Published var preventDisplay = false
    @Published private(set) var isActive = false

    private var assertion: IOPMAssertionID = 0
    private init() {}

    func start() {
        guard !isActive else { return }
        let type = preventDisplay ? kIOPMAssertionTypeNoDisplaySleep
                                  : kIOPMAssertionTypeNoIdleSleep
        var id: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "StayAwake running" as CFString,
            &id
        )
        if result == kIOReturnSuccess {
            assertion = id
            isActive = true
        }
    }

    func stop() {
        if assertion != 0 {
            IOPMAssertionRelease(assertion)
            assertion = 0
        }
        isActive = false
    }

    func restartIfActive() {
        if isActive { stop(); start() }
    }
}

// Use an app delegate for lifecycle hooks (Scenes don't have onAppear)
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        SleepKeeper.shared.start()
    }
    func applicationWillTerminate(_ notification: Notification) {
        SleepKeeper.shared.stop()
    }
}

@main
struct StayAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var keeper = SleepKeeper.shared

    var body: some Scene {
        MenuBarExtra(keeper.isActive ? "Awake" : "Idle",
                     systemImage: keeper.isActive ? "bolt.fill" : "bolt.slash") {
            Toggle("Prevent display sleep", isOn: $keeper.preventDisplay)
                .onChange(of: keeper.preventDisplay) { _ in keeper.restartIfActive() }

            Button(keeper.isActive ? "Stop keeping awake" : "Start keeping awake") {
                if keeper.isActive { keeper.stop() } else { keeper.start() }
            }

            Divider()
            Button("Quit") { NSApp.terminate(nil) }
        }
    }
}
