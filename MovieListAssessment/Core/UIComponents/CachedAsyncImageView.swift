//
//  UIComponents.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//
import SwiftUI
import Combine

struct CachedAsyncImageView: View {
  // @StateObject garante que o ImageLoaderViewModel seja mantido vivo pela View
  // e recriado apenas se a identidade da View mudar (baseada na URL).
  @StateObject private var imageLoader: ImageLoaderViewModel
  
  // Placeholder customizável
  private var placeholder: AnyView?
  
  public init(url: URL?, @ViewBuilder placeholder: @escaping () -> some View = { ProgressView() }) {
    // O _imageLoader é inicializado com o wrappedValue.
    // A URL é a "identidade" para o @StateObject. Se a URL mudar, um novo ImageLoaderViewModel será criado.
    _imageLoader = StateObject(wrappedValue: ImageLoaderViewModel(url: url))
    self.placeholder = AnyView(placeholder())
  }
  
  var body: some View {
    Group {
      if let uiImage = imageLoader.image {
        Image(uiImage: uiImage)
          .resizable() // Torna a imagem redimensionável por padrão
      } else if imageLoader.isLoading {
        placeholder // Mostra o placeholder enquanto carrega
      } else {
        // Estado de erro ou inicial (URL nula ou falha no carregamento)
        ZStack { // Usar ZStack para sobrepor um ícone de erro no placeholder
          placeholder
          if imageLoader.errorMessage != nil || imageLoader.url == nil { // Mostrar ícone se erro ou URL nula
            Image(systemName: "photo.fill.on.rectangle.fill") // Ícone de placeholder/erro
              .resizable()
              .scaledToFit()
              .frame(width: 30, height: 30) // Ajuste o tamanho do ícone
              .foregroundColor(.gray.opacity(0.7))
          }
        }
      }
    }
    .onAppear {
      imageLoader.loadImage()
    }
    // .onDisappear {
    // imageLoader.cancelLoading() // Opcional: cancelar se a view some.
    // Pode não ser desejável se você quiser que o download continue em segundo plano
    // para que a imagem esteja pronta quando a view reaparecer.
    // Se cancelar, o NSCache ainda manterá a imagem se o download foi concluído.
    // }
  }
}
