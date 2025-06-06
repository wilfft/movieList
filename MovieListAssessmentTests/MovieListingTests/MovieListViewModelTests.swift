//
//  File.swift
//  MovieListAssessmentTests
//
//  Created by William Moraes da Silva on 03/06/25.
//

#if DEBUG
import XCTest
import Combine
@testable import MovieListAssessment

@MainActor
final class MovieListViewModelTests: XCTestCase {

    var viewModel: MovieListViewModel!
    var mockRepository: MockMovieRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockMovieRepository()
        viewModel = MovieListViewModel(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        cancellables = nil
        super.tearDown()
    }

  func test_fetchMovies_initialLoad_success() async {
      // Arrange
      let moviesData = [Movie(id: 1, title: "Filme 1", overview: "o1", posterPath: nil, voteAverage: 7.0)]
      let apiResponse = MovieApiResponse(page: 1, results: moviesData, totalPages: 2, totalResults: 10)
      mockRepository.mockedResponse = .success(apiResponse)
      
      let moviesLoadedExpectation = XCTestExpectation(description: "Movies should be loaded")
      
      viewModel.$movies
          .dropFirst()
          .filter { !$0.isEmpty }
          .sink { loadedMovies in
              moviesLoadedExpectation.fulfill()
          }
          .store(in: &cancellables)

      // Act
      await viewModel.fetchMovies(isInitialLoad: true)

      // Assert (Espera)
      await fulfillment(of: [moviesLoadedExpectation], timeout: 2.0)
      
      XCTAssertEqual(viewModel.movies.count, moviesData.count, "O número de filmes carregados não corresponde.")
      XCTAssertEqual(viewModel.movies.first?.id, moviesData.first?.id, "O primeiro filme não corresponde.")
      XCTAssertFalse(viewModel.isLoading, "isLoading deveria ser false após o carregamento completo.")
      XCTAssertNil(viewModel.errorMessage, "errorMessage deveria ser nil em caso de sucesso.")
      XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 1, "getPopularMovies deveria ser chamado 1 vez.")
      XCTAssertEqual(mockRepository.lastPageCalled, 1, "A página correta deveria ter sido chamada.")
  }

  func test_fetchMovies_failure_setsErrorMessage() async {
      // Arrange
      let expectedError = AppError.networkError(URLError(.notConnectedToInternet))
      mockRepository.mockedResponse = .failure(expectedError)
      
      let errorMessageIsSetExpectation = XCTestExpectation(description: "Error message should be set")

      
      viewModel.$errorMessage
          .dropFirst()
          .filter { $0 != nil }
          .sink { errorMessageValue in
              errorMessageIsSetExpectation.fulfill()
          }
          .store(in: &cancellables)

      // Act
      await viewModel.fetchMovies(isInitialLoad: true)
      
      // Assert
      await fulfillment(of: [errorMessageIsSetExpectation], timeout: 2.0)
      
      XCTAssertTrue(viewModel.movies.isEmpty, "A lista de filmes deveria estar vazia em caso de erro.")
      XCTAssertFalse(viewModel.isLoading, "isLoading deveria ser false após a falha.") // Verifique agora
      XCTAssertNotNil(viewModel.errorMessage, "errorMessage não deveria ser nil.")
      XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription, "A mensagem de erro não corresponde à esperada.")
      XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 1, "getPopularMovies deveria ter sido chamado 1 vez.")
      XCTAssertTrue(viewModel.canLoadMorePages, "canLoadMorePages deveria ser true após uma tentativa de initialLoad, mesmo que falhe.")
  }
    
    func test_loadMoreMoviesIfNeeded_triggersFetchWhenNearEnd() async {
        let initialMovies = (1...10).map { Movie(id: $0, title: "F\($0)", overview: "o\($0)", posterPath: nil, voteAverage: 7) }
        let initialResponse = MovieApiResponse(page: 1, results: initialMovies, totalPages: 2, totalResults: 20)
        mockRepository.mockedResponse = .success(initialResponse)
        await viewModel.fetchMovies(isInitialLoad: true)
        
        let nextPageMovies = [Movie(id: 11, title: "F11", overview: "o11", posterPath: nil, voteAverage: 8)]
        let nextPageResponse = MovieApiResponse(page: 2, results: nextPageMovies, totalPages: 2, totalResults: 20)
        mockRepository.mockedResponse = .success(nextPageResponse)

        await viewModel.loadMoreMoviesIfNeeded(currentMovie: viewModel.movies[5])

        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 2)
        XCTAssertEqual(mockRepository.lastPageCalled, 2)
    }
}
#endif
