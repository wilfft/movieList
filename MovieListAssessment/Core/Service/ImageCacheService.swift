//
//  ImageCacheService.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import UIKit
import Combine

private class CachedImage {
  let image: UIImage
  
  init(_ image: UIImage) {
    self.image = image
  }
}

public final class ImageCacheService {
  public static let shared = ImageCacheService() // Singleton
  
  // NSURL será usada como chave
  private let memoryCache = NSCache<NSURL, CachedImage>()
  
  // Para evitar downloads duplicados para a mesma URL ao mesmo tempo
  private var loadingResponses: [NSURL: AnyPublisher<UIImage, Error>] = [:]
  private let lock = NSLock() // Para proteger o acesso a loadingResponses
  
  private init() {
    memoryCache.countLimit = 100
    memoryCache.totalCostLimit = 1024 * 1024 * 50
  }
  
  func getImage(forKey key: URL) -> UIImage? {
    return memoryCache.object(forKey: key as NSURL)?.image
  }
  
  private func setImage(_ image: UIImage, forKey key: URL) {
    let cachedItem = CachedImage(image)
    
    let cost = image.pngData()?.count ?? image.jpegData(compressionQuality: 1.0)?.count ?? 0
    memoryCache.setObject(cachedItem, forKey: key as NSURL, cost: cost)
  }
  
  // Remove uma imagem específica do cache
  func removeImage(forKey key: URL) {
    memoryCache.removeObject(forKey: key as NSURL)
  }
  
  // Limpa todo o cache de imagens
  func clearAllImages() {
    memoryCache.removeAllObjects()
  }
  
  // Função para carregar imagem: primeiro tenta o cache, depois a rede.
  // Retorna um publisher que emitirá a UIImage ou um erro.
  // Esta função lida com a prevenção de downloads duplicados.
  func loadImage(from url: URL) -> AnyPublisher<UIImage, Error> {
    // 1. Tenta obter do cache
    if let cachedImage = getImage(forKey: url) {
      return Just(cachedImage)
        .setFailureType(to: Error.self) // Just não falha, então alinhamos o tipo de erro
        .eraseToAnyPublisher()
    }
    
    lock.lock() // Proteger o acesso a loadingResponses
    
    // 2. Verifica se já existe um download em andamento para esta URL
    if let existingPublisher = loadingResponses[url as NSURL] {
      lock.unlock()
      return existingPublisher
    }
    
    // 3. Se não estiver no cache e não estiver carregando, inicia um novo download
    // Usando URLSession.shared.dataTaskPublisher para uma abordagem com Combine
    let newPublisher = URLSession.shared.dataTaskPublisher(for: url)
      .map(\.data) // Extrai os dados
      .tryMap { data -> UIImage in
        guard let image = UIImage(data: data) else {
          throw AppError.decodingError(NSError(domain: "ImageCacheService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Não foi possível criar UIImage a partir dos dados."]))
        }
        return image
      }
      .handleEvents(receiveOutput: { [weak self] image in
        // Cacheia a imagem após o download bem-sucedido
        self?.setImage(image, forKey: url)
      }, receiveCompletion: { [weak self] _ in
        // Remove o publisher da lista de 'loadingResponses' quando completar (sucesso ou falha)
        self?.lock.lock()
        self?.loadingResponses.removeValue(forKey: url as NSURL)
        self?.lock.unlock()
      })
      .share() // Importante: Compartilha o resultado do publisher entre múltiplos assinantes
    // se a mesma URL for requisitada várias vezes antes do primeiro download completar.
      .eraseToAnyPublisher()
    
    loadingResponses[url as NSURL] = newPublisher
    lock.unlock()
    
    return newPublisher
  }
}
