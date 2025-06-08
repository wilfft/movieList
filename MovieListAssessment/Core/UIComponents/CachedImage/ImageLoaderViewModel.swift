//
//  File.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import SwiftUI
import Combine
// possibilidade usar frameworks como snapkit

@MainActor //dispensavel por ja to passando pra main thread no receive
final class ImageLoaderViewModel: ObservableObject {
  @Published var image: UIImage?
  @Published var isLoading: Bool = false
  @Published var errorMessage: String? = nil
  
  let url: URL?
  private var cancellable: AnyCancellable?
  private let imageCache: ImageCacheServiceProtocol
  
  init(url: URL?, imageCache: ImageCacheServiceProtocol = ImageCacheService.shared) {
    self.url = url
    self.imageCache = imageCache
  }
  
  func loadImage() {
    guard let url = url else {
      return
    }
    
    guard image == nil, !isLoading else { return }
    
    isLoading = true
    errorMessage = nil
    
    // cancellable, recebe um AnyCancelable, que vem de uma operação assincrono
    cancellable = imageCache.loadImage(from: url)
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { [weak self] completion in
        self?.isLoading = false
        if case .failure(let error) = completion {
          self?.errorMessage = "Falha: \(error.localizedDescription)"
          print("ImageLoaderViewModel: Erro ao carregar imagem de \(url): \(error.localizedDescription)")
        }
      }, receiveValue: { [weak self] loadedImage in
        self?.image = loadedImage
      })
  }
}
