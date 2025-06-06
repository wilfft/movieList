//
//  ImageCacheService.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import UIKit
import Combine

private class CachedImageItem {
    let image: UIImage
    init(_ image: UIImage) {
        self.image = image
    }
}
 
final class ImageCacheService: ImageCacheServiceProtocol {
    static let shared = ImageCacheService()

    private let memoryCache = NSCache<NSURL, CachedImageItem>()
    private var loadingResponses: [NSURL: AnyPublisher<UIImage, Error>] = [:]
    private let lock = NSLock()

    private init() {
        memoryCache.countLimit = 150
        memoryCache.totalCostLimit = 1024 * 1024 * 100 // 100MB
    }

    private func getImage(forKey key: URL) -> UIImage? {
        return memoryCache.object(forKey: key as NSURL)?.image
    }

    private func setImage(_ image: UIImage, forKey key: URL) {
        let cachedItem = CachedImageItem(image)
        let cost = image.pngData()?.count ?? image.jpegData(compressionQuality: 1.0)?.count ?? 0
        memoryCache.setObject(cachedItem, forKey: key as NSURL, cost: cost)
    }

    func loadImage(from url: URL) -> AnyPublisher<UIImage, Error> {
        if let cachedImage = getImage(forKey: url) {
            return Just(cachedImage)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        lock.lock()
        if let existingPublisher = loadingResponses[url as NSURL] {
            lock.unlock()
            return existingPublisher
        }

        let newPublisher = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .tryMap { data -> UIImage in
                guard let image = UIImage(data: data) else {
                    throw NSError(domain: "ImageCacheService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Falha ao decodificar imagem"])
                }
                return image
            }
            .handleEvents(receiveOutput: { [weak self] image in
                self?.setImage(image, forKey: url)
            }, receiveCompletion: { [weak self] _ in
                self?.lock.lock()
                self?.loadingResponses.removeValue(forKey: url as NSURL)
                self?.lock.unlock()
            })
            .share()
            .eraseToAnyPublisher()

        loadingResponses[url as NSURL] = newPublisher
        lock.unlock()
        return newPublisher
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        // Também limpar loadingResponses se houver algum download pendente que não queremos mais
        lock.lock()
        loadingResponses.removeAll()
        lock.unlock()
        print("ImageCacheService: Cache de memória limpo.")
    }
}

