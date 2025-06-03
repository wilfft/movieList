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
        let movies = [Movie(id: 1, title: "Filme 1", overview: "o1", posterPath: nil, voteAverage: 7.0)]
        let apiResponse = MovieApiResponse(page: 1, results: movies, totalPages: 2, totalResults: 10)
        mockRepository.mockedResponse = .success(apiResponse)
        let expectation = XCTestExpectation(description: "Filmes carregados")
        
        viewModel.$movies.dropFirst().sink { loadedMovies in
            if !loadedMovies.isEmpty && !self.viewModel.isLoading { expectation.fulfill() }
        }.store(in: &cancellables)

        await viewModel.fetchMovies(isInitialLoad: true)
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(viewModel.movies.count, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 1)
    }

    func test_fetchMovies_failure_setsErrorMessage() async {
        let expectedError = AppError.networkError(URLError(.notConnectedToInternet))
        mockRepository.mockedResponse = .failure(expectedError)
        let expectation = XCTestExpectation(description: "Erro definido")

        viewModel.$errorMessage.dropFirst().sink { errorMessage in
            if errorMessage != nil && !self.viewModel.isLoading { expectation.fulfill() }
        }.store(in: &cancellables)

        await viewModel.fetchMovies(isInitialLoad: true)
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertTrue(viewModel.movies.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription)
    }
    
    func test_loadMoreMoviesIfNeeded_triggersFetchWhenNearEnd() async {
        let initialMovies = (1...10).map { Movie(id: $0, title: "F\($0)", overview: "o\($0)", posterPath: nil, voteAverage: 7) }
        let initialResponse = MovieApiResponse(page: 1, results: initialMovies, totalPages: 2, totalResults: 20)
        mockRepository.mockedResponse = .success(initialResponse)
        await viewModel.fetchMovies(isInitialLoad: true)
        
        let nextPageMovies = [Movie(id: 11, title: "F11", overview: "o11", posterPath: nil, voteAverage: 8)]
        let nextPageResponse = MovieApiResponse(page: 2, results: nextPageMovies, totalPages: 2, totalResults: 20)
        mockRepository.mockedResponse = .success(nextPageResponse)

        // O item no índice 5 é o 6º filme (movies.count (10) - 5 = 5)
        await viewModel.loadMoreMoviesIfNeeded(currentMovie: viewModel.movies[5])

        XCTAssertEqual(mockRepository.getPopularMoviesCallCount, 2)
        XCTAssertEqual(mockRepository.lastPageCalled, 2)
    }
}
#endif
