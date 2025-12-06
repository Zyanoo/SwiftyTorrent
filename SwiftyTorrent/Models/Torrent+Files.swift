//
//  Torrent.swift
//  SwiftyTorrent
//
//  Created by Danylo Kostyshyn on 7/15/19.
//  Copyright © 2019 Danylo Kostyshyn. All rights reserved.
//

import TorrentKit

extension Torrent {
    
    private var torrentManager: TorrentManagerProtocol {
        resolveComponent(TorrentManagerProtocol.self)        
    }
    
    private static var filesCache = [Data: [FileEntry]]()
    private static var dirsCache = [Data: Directory]()
    
    private var fileEntries: [FileEntry] {
        if let files = Torrent.filesCache[infoHash] {
            return files
        }

        let files = torrentManager.filesForTorrent(withHash: infoHash) ?? []
        if !files.isEmpty {
            Torrent.filesCache[infoHash] = files
        }
        return files
    }

    var directory: Directory {
        if let dir = Torrent.dirsCache[infoHash] {
            return dir
        }

        let dir = Directory.directory(from: fileEntries)
        if !fileEntries.isEmpty {
            Torrent.dirsCache[infoHash] = dir
        }
        return dir
    }

}
