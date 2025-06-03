//
//  File.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import SwiftUI
import Combine

@MainActor // Garante que as atualizações de @Published aconteçam na thread principal
final class ImageLoaderViewModel: ObservableObject {
  @Published var image: UIImage?
  @Published var isLoading: Bool = false
  @Published var errorMessage: String? = nil // Para depuração ou feedback de erro na UI
  
  let url: URL?
  private var cancellable: AnyCancellable?
  private let imageCache = ImageCacheService.shared // Usa o singleton do ImageCacheService
  
  init(url: URL?) {
    self.url = url
  }
  
  func loadImage() {
    guard let url = url else {
      // Se a URL for nula, não há o que carregar.
      // Pode definir um estado de erro aqui se uma URL fosse esperada.
      return
    }
    
    // Não recarregar se já tiver uma imagem ou já estiver carregando
    guard image == nil, !isLoading else { return }
    
    isLoading = true
    errorMessage = nil
    
    // Usa a função loadImage do ImageCacheService que retorna um Publisher
    cancellable = imageCache.loadImage(from: url)
      .receive(on: DispatchQueue.main) // Garante que a UI seja atualizada na thread principal
      .sink(receiveCompletion: { [weak self] completion in
        self?.isLoading = false
        switch completion {
        case .failure(let error):
          self?.errorMessage = "Falha ao carregar imagem: \(error.localizedDescription)"
          print("ImageLoaderViewModel: Erro ao carregar imagem de \(url): \(error.localizedDescription)")
          // Você poderia definir uma imagem de placeholder de erro aqui se desejado
        case .finished:
          break
        }
      }, receiveValue: { [weak self] loadedImage in
        self?.image = loadedImage
      })
  }
  
  func cancelLoading() {
    cancellable?.cancel()
    isLoading = false // Garante que isLoading seja resetado se o carregamento for cancelado
  }
  
  // Chamado quando a view que usa este loader desaparece.
  // Podemos decidir se cancelamos o download ou deixamos continuar para cachear.
  deinit {
    // print("ImageLoaderViewModel deinit para URL: \(url?.absoluteString ?? "nil")")
    // cancellable?.cancel() // Opcional: cancelar aqui também.
  }
}
