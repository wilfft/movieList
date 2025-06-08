//
//  ImageCacheService.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import UIKit
import Combine

 // opçao usando AsyncAwait
 // troca pra asyc awit pois já uso no API

final class ImageCacheService: ImageCacheServiceProtocol {
    static let shared = ImageCacheService()
   // desperdiçaria cache ja carregado
   // cache de imagem compartilhado com todo o app, acessado por todos.

    let memoryCache = NSCache<NSURL, CachedImageItem>()
    private var loadingResponses: [NSURL: AnyPublisher<UIImage, Error>] = [:] //armazena as urls que estao sendo baixadas
    private let lock = NSLock() // thread safety

    private init() {
        memoryCache.countLimit = 150
        memoryCache.totalCostLimit = 1024 * 1024 * 100 // 100MB
    }

    private func getImage(forKey key: URL) -> UIImage? {
        return memoryCache.object(forKey: key as NSURL)?.image // pego da memoria a key URL
    }

    private func setImage(_ image: UIImage, forKey key: URL) {
        let cachedItem = CachedImageItem(image)
        let cost = image.pngData()?.count ?? image.jpegData(compressionQuality: 1.0)?.count ?? 0
        memoryCache.setObject(cachedItem, forKey: key as NSURL, cost: cost)
    }

    func loadImage(from url: URL) -> AnyPublisher<UIImage, Error> {
        if let cachedImage = getImage(forKey: url) { // pesquisa pela key no cache www.abc.com
          return Just(cachedImage) // se estiver, retorna imagem
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        lock.lock() // thread safety-> bloqueia que outras threads acessem a mesma imagem
        // verifica se já existe uma requisicao pra essa url e retorna o publisher ja existende
        if let existingPublisher = loadingResponses[url as NSURL] {
            lock.unlock()
            return existingPublisher
        }
      
        // inicia carregamento para puxar a imagem da internet
        let newPublisher = URLSession.shared.dataTaskPublisher(for: url) // cria um puplisher compartilhado
            .map(\.data)
            .tryMap { data -> UIImage in
                guard let image = UIImage(data: data) else {
                    throw NSError(domain: "ImageCacheService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Falha ao decodificar imagem"])
                }
                return image
            }
            .handleEvents(receiveOutput: { [weak self] image in
                self?.setImage(image, forKey: url) // passa a imagem decodificado para uma UIImage
            }, receiveCompletion: { [weak self] _ in // remove a url da lista de requests em andamento
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
