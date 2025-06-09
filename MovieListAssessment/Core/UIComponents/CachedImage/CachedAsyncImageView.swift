//
//  UIComponents.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//
import SwiftUI
import Combine

struct CachedAsyncImageView: View {
  @StateObject private var imageLoader: ImageLoaderViewModel
  
  private var placeholder: AnyView?
  
  public init(url: URL?, @ViewBuilder placeholder: @escaping () -> some View = { ProgressView() }) {
    
    _imageLoader = StateObject(wrappedValue: ImageLoaderViewModel(url: url))
    self.placeholder = AnyView(placeholder())
  }
  
  var body: some View {
    Group {
      if let uiImage = imageLoader.image {
        Image(uiImage: uiImage)
          .resizable()
      } else if imageLoader.isLoading {
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
