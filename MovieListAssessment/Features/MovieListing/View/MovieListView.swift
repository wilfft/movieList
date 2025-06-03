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
  
  init(viewModel: MovieListViewModel = MovieListViewModel()) {
    // Agora, o corpo deste init está garantido para rodar no MainActor
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
        
        if viewModel.isLoading && !viewModel.movies.isEmpty { // Só mostra "Carregando mais" se já houver filmes
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
      .overlay { // Para loading inicial
        if viewModel.isLoading && viewModel.movies.isEmpty {
          ProgressView("Carregando filmes...")
        }
      }
      .navigationTitle("Filmes Populares")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          // Não mostra refresh se estiver no loading inicial ou se não houver filmes
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
        if viewModel.movies.isEmpty { // Carrega filmes apenas se a lista estiver vazia
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
