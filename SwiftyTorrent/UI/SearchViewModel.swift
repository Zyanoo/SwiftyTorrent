//
//  SearchViewModel.swift
//  SwiftyTorrent
//
//  Created by Danylo Kostyshyn on 29.06.2020.
//  Copyright © 2020 Danylo Kostyshyn. All rights reserved.
//

import Combine
import SwiftUI
import TorrentKit

final class SearchViewModel: ObservableObject {
    
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var items = [SearchDataItem]()
    
    private var currentPage = 1
    private var hasMorePages = false
    
    private let imdbProvider = resolveComponent(IMDBDataProviderProtocol.self)
    private let eztbProvider = resolveComponent(EZTVDataProviderProtocol.self)
    private let torrentManager = resolveComponent(TorrentManagerProtocol.self)
    
    private var cancellables = [AnyCancellable]()
    
    init() {
        $searchText
            .handleEvents(receiveOutput: { [weak self] text in
                // Clear results if `searchText` is empty
                if text.isEmpty {
                    self?.items = []
                }
            })
            .filter { !$0.isEmpty }
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isLoading = true
                self?.currentPage = 1
                self?.hasMorePages = true
            })
            .map { [weak self] query -> AnyPublisher<String, Never> in
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                return self.imdbProvider.fetchSuggestions(query)
                    .replaceError(with: "")
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .map { [weak self] imdbId -> AnyPublisher<[SearchDataItem], Never> in
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                return self.eztbProvider.fetchTorrents(imdbId: imdbId, page: 1)
                    .replaceError(with: [])
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isLoading = false
            })
            .sink(receiveValue: { [weak self] items in
                self?.items = items
            })
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: -

    func loadMoreIfNeeded(currentItem item: SearchDataItem) {
        let thresholdIdx = items.index(items.endIndex, offsetBy: -5)
        if items.firstIndex(where: { $0.id == item.id }) == thresholdIdx {
            loadMore()
        }
    }
    
    private func loadMore() {
        guard !isLoading && hasMorePages else { return }

        isLoading = true
        
        imdbProvider.fetchSuggestions(searchText)
            .map { [weak self] imdbId -> AnyPublisher<[SearchDataItem], Error> in
                guard let self = self else { return Fail(error: URLError(.cancelled)).eraseToAnyPublisher() }
                return self.eztbProvider.fetchTorrents(imdbId: imdbId, page: self.currentPage + 1)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] items in
                self?.isLoading = false
                self?.currentPage += 1
                self?.hasMorePages = !items.isEmpty
            })
            .map { [weak self] items in
                return (self?.items ?? []) + items
            }
            .catch({ [weak self] _ in Just(self?.items ?? []) })
            .sink(receiveValue: { [weak self] items in
                self?.items = items
            })
            .store(in: &cancellables)
    }
    
    func select(_ item: SearchDataItem) {
        let magnetURI = MagnetURI(magnetURI: item.magnetURL)
        torrentManager.add(magnetURI)
    }
    
}
