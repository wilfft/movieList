//
//  UIComponents.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//
import SwiftUI
import Combine

  // logica encapsulada, nao consigo acessar de fora (cancelar, reaproveitar)
struct CachedAsyncImageView: View {
  @StateObject private var imageLoader: ImageLoaderViewModel // state objeto para manter o estado da VM
  
  private var placeholder: AnyView?
  
  public init(url: URL?, @ViewBuilder placeholder: @escaping () -> some View = { ProgressView() }) {
    // A URL é a "identidade" para o @StateObject. Se a URL mudar, um novo ImageLoaderViewModel será criado.
    _imageLoader = StateObject(wrappedValue: ImageLoaderViewModel(url: url))
    self.placeholder = AnyView(placeholder()) //  overhead de performance
  }
  
  var body: some View {
    Group {
      if let uiImage = imageLoader.image { // UIimage
        Image(uiImage: uiImage)
          .resizable()
      } else if imageLoader.isLoading { // placeholder enquanto carrega
        placeholder
      } else {
        ZStack {
          placeholder
          if imageLoader.errorMessage != nil || imageLoader.url == nil {
            Image(systemName: "photo.fill.on.rectangle.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 30, height: 30)
              .foregroundColor(.gray.opacity(0.7))
          }
        }
      }
    }
    .onAppear {
      imageLoader.loadImage() 
    }
  }
}
