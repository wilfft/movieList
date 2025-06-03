//
//  Untitled.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Combine

final class MovieListViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var canLoadMorePages: Bool = true

    private var currentPage = 1
    private var totalPages = 1
    private var itensLimits = -5
    private let repository: MovieRepositoryProtocol

    init(repository: MovieRepositoryProtocol = MovieRepository(apiService: MovieAPIService())) {
        self.repository = repository
    }

    @MainActor
    func fetchMovies(isInitialLoad: Bool = true) async {
        if isInitialLoad {
            currentPage = 1
            movies = [] // Limpa para carregamento inicial ou refresh
            canLoadMorePages = true
        }

        guard !isLoading, canLoadMorePages else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await repository.getPopularMovies(page: currentPage)
            
            // Adiciona apenas filmes novos para evitar duplicação se a API retornar algo já existente
  
            let newMovies = response.results.filter { newMovie in
                !self.movies.contains { $0.id == newMovie.id }
            }
            movies.append(contentsOf: newMovies)
            
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

  @MainActor
    func loadMoreMoviesIfNeeded(currentMovie movie: Movie?) async {
        guard let movie = movie else {
            if !isLoading && movies.isEmpty { // Primeiro load se a lista estiver vazia
                await fetchMovies(isInitialLoad: true)
            }
            return
        }

        // Carregar quando estiver a 5 itens do fim
        let thresholdIndex = movies.index(movies.endIndex, offsetBy: -5)
        if movies.firstIndex(where: { $0.id == movie.id }) == thresholdIndex && canLoadMorePages && !isLoading {
            currentPage += 1
            await fetchMovies(isInitialLoad: false)
        }
    }
}
