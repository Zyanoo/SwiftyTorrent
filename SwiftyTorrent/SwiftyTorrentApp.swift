//
//  SwiftyTorrentApp.swift
//  SwiftyTorrent
//
//  Created by Jules on 10/26/2023.
//

import SwiftUI
import TorrentKit
import UserNotifications

@main
struct SwiftyTorrentApp: App {

    @Environment(\.scenePhase) private var scenePhase

    private let torrentManager: TorrentManagerProtocol

    init() {
        registerDependencies()
        torrentManager = resolveComponent(TorrentManagerProtocol.self)

        requestUserNotifications()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .onOpenURL { url in
                    torrentManager.open(url)
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                handleBackgroundTask()
            }
        }
    }

    private func requestUserNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (_, error) in
            if let error = error {
                print("\(error.localizedDescription)")
            }
        }
    }

    private func handleBackgroundTask() {
        // Keep the app alive in background as long as possible until the system kills it (expiration).
        // This mimics the original AppCoordinator behavior which allowed the session to persist.
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            // Expiration handler
            print("Background task ended (expired).")
            showLocalNotification()
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }

        print("Background task started.")
    }

    private func showLocalNotification() {
        #if os(iOS)
        let content = UNMutableNotificationContent()
        content.title = "SwiftyTorrent"
        content.body = "Suspending session..."
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "SuspendingSession", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error: Error?) in
            if let error = error {
                print("\(error.localizedDescription)")
            }
        }
        #endif
    }
}
