//
//  Mo.swift
//  MovieListAssessmentTests
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Foundation
@testable import MovieListAssessment

final class MockMovieAPIService: MovieAPIServiceProtocol {
    var mockResponse: Result<MovieApiResponse, AppError>?
    var fetchPopularMoviesCallCount = 0
    var lastPageCalled: Int?

    func fetchPopularMovies(page: Int) async throws -> MovieApiResponse {
        fetchPopularMoviesCallCount += 1
        lastPageCalled = page
        
        guard let response = mockResponse else {
            fatalError("MockMovieAPIService.mockResponse não foi configurado.")
        }
        
        switch response {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}
