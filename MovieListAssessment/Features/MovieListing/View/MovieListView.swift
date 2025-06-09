//
//  Untitled.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import SwiftUI

struct MovieListView: View {
  @StateObject private var viewModel: MovieListViewModel
  @State private var showErrorAlert: Bool = false
  
  
  init(viewModel: MovieListViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  var body: some View {
    NavigationView {
      List {
        ForEach(viewModel.movies) { movie in
          MovieRowView(movie: movie)
            .onAppear {
              Task { 
                await viewModel.loadMoreMoviesIfNeeded(currentMovie: movie)
              }
            }
        }
        
        if viewModel.isLoading && !viewModel.movies.isEmpty {
          HStack {
            Spacer()
            ProgressView("Carregando mais...")
              .padding()
            Spacer()
          }
        }
        
        if !viewModel.canLoadMorePages && !viewModel.movies.isEmpty && !viewModel.isLoading {
          Text("Todos os filmes foram carregados.")
            .font(.caption)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
      }
      .overlay {
        if viewModel.isLoading && viewModel.movies.isEmpty {
          ProgressView("Carregando filmes...")
        }
      }
      .navigationTitle("Filmes Populares")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          if !viewModel.movies.isEmpty && !viewModel.isLoading {
            Button {
              Task {
                await viewModel.fetchMovies(isInitialLoad: true)
              }
            } label: {
              Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading)
          }
        }
      }
      .onAppear {
        if viewModel.movies.isEmpty {
          Task {
            await viewModel.fetchMovies(isInitialLoad: true)
          }
        }
      }
      .onChange(of: viewModel.errorMessage) { newErrorMessage in
        showErrorAlert = newErrorMessage != nil
      }
      .alert(
        "Erro",
        isPresented: $showErrorAlert,
        actions: {
          Button("OK") {
            viewModel.errorMessage = nil
          }
        },
        message: {
          Text(viewModel.errorMessage ?? "Ocorreu um erro desconhecido.")
        }
      )
    }
  }
}
