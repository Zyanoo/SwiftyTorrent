//
//  SwiftyTVApp.swift
//  SwiftyTV
//
//  Created by Jules on 10/26/2023.
//

import SwiftUI
import TorrentKit

@main
struct SwiftyTVApp: App {

    private let torrentManager: TorrentManagerProtocol

    init() {
        registerDependencies()
        torrentManager = resolveComponent(TorrentManagerProtocol.self)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
