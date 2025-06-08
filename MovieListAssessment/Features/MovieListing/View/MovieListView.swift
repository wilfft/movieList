//
//  Untitled.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import SwiftUI

struct MovieListView: View {
  @StateObject private var viewModel: MovieListViewModel // state = value types
  // @StateObject é para quando a view é a proprietária e criadora do objeto, garantindo sua persistência.
  // @ObservedObject é para objetos cujo ciclo de vida é externo à view
  @State private var showErrorAlert: Bool = false
  // @State erro mais simples de ser manuseado, poderia ter alocado pro VM
  
  
  init(viewModel: MovieListViewModel) {
    // exigir injeçao sempre, mais desacoplado, força a depedencia (DI, Coordinator)
    // conveniencia, facilidade no preview
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  var body: some View {
    NavigationView { // container de naveçao , necessário para haver hierarquia
      List { // Scroll + LazyVStack, maior controle, nao tem espaçamento ou separador
            // List já possui melhorias de perfomance instrinseca
        ForEach(viewModel.movies) { movie in
          MovieRowView(movie: movie)
            .onAppear {
              Task { // contexto assincrono
                await viewModel.loadMoreMoviesIfNeeded(currentMovie: movie)
              }
            }
        }
        
        if viewModel.isLoading && !viewModel.movies.isEmpty { // mostra "Carregando mais" se já houver filmes
          HStack {
            Spacer()
            ProgressView("Carregando mais...")
              .padding()
            Spacer()
          }
        }
        
        if !viewModel.canLoadMorePages && !viewModel.movies.isEmpty && !viewModel.isLoading {  // mostra que todos filmes foram carregados, nao pode mais carregar paginas, ja tem filmes na viewModel e nao tem loading ativo
          Text("Todos os filmes foram carregados.")
            .font(.caption)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
      }
      .overlay { // loading inicial
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
              Task { // chamada assincrona para trazer os filmes, ao clicar em refresher, vai trazer pagina zero
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
          Task { // chamada assincrona para trazer os filmes, load inicial, vai trazer pagina zero
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
