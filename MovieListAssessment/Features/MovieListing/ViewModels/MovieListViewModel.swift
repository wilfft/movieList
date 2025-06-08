//
//  Untitled.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Combine

@MainActor
final class MovieListViewModel: ObservableObject {
  @Published var movies: [Movie] = []
  @Published var isLoading: Bool = false
  @Published var errorMessage: String? = nil
  @Published var canLoadMorePages: Bool = true
  
  private var currentPage = 1
  private var totalPages = 1
  private var offSetToLoadMoreItens = -5
  private let repository: MovieRepositoryProtocol
  
  init(repository: MovieRepositoryProtocol = MovieRepository(apiService: MovieAPIService())) {
    self.repository = repository
  }
  
  // chamda async, nao deveria acessar as funçoes diretamente por isso preciso do mainActor
  func fetchMovies(isInitialLoad: Bool = true) async {
    if isInitialLoad {
      currentPage = 1
      movies = [] // Limpa para carregamento inicial ou refresh, garante na main thread com main actor
      canLoadMorePages = true
    }
    
    // caso nao estiver carregando e puder trazer mais paginas
    guard !isLoading, canLoadMorePages else { return }
    
    isLoading = true // ✅ Garantido na main thread
    errorMessage = nil
    
    // tratamento de requisiçao
    do {
      // traz os filmes do repositorio, de forma assincrona
      let response = try await repository.getPopularMovies(page: currentPage)
      
      // Adiciona apenas filmes novos para evitar duplicação se a API retornar algo já existente
      let newMovies = response.results.filter { newMovie in
        !self.movies.contains { $0.id == newMovie.id }
      }
      movies.append(contentsOf: newMovies) // ✅ Garantido na main thread
      
      totalPages = response.totalPages
      if currentPage >= totalPages {
        canLoadMorePages = false
      }
      isLoading = false
    } catch let error as AppError {
      errorMessage = error.localizedDescription
      isLoading = false
      print("Erro ao buscar filmes: \(error.localizedDescription)")
    } catch {
      errorMessage = "Um erro inesperado ocorreu: \(error.localizedDescription)"
      isLoading = false
      print("Erro desconhecido ao buscar filmes: \(error.localizedDescription)")
    }
  }
  
  func loadMoreMoviesIfNeeded(currentMovie movie: Movie?) async {
    guard let movie = movie else {
      if !isLoading && movies.isEmpty { // Primeiro load se a lista estiver vazia
        await fetchMovies(isInitialLoad: true)
      }
      return
    }
    
    // Carregar quando estiver a 5 itens do fim
    // safety: nao permite trazer mais itens enquanto já estiver carregando algum
    let thresholdIndex = movies.index(movies.endIndex, offsetBy: offSetToLoadMoreItens)
    if movies.firstIndex(where: { $0.id == movie.id }) == thresholdIndex && canLoadMorePages && !isLoading {
      currentPage += 1
      // ao alcançar 5 items pro fim da lista, traz mais filmes mas não é load inicial
      await fetchMovies(isInitialLoad: false)
    }
  }
}
