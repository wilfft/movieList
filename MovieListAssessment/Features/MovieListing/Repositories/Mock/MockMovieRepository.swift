//
//  File.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Foundation

final class MockMovieRepository: MovieRepositoryProtocol {
    var mockedResponse: Result<MovieApiResponse, AppError>?
    var getPopularMoviesCallCount = 0
    var lastPageCalled: Int?

    init(mockedResponse: Result<MovieApiResponse, AppError>? = nil) {
        self.mockedResponse = mockedResponse
    }

    func getPopularMovies(page: Int) async throws -> MovieApiResponse {
        getPopularMoviesCallCount += 1
        lastPageCalled = page
        
        guard let response = mockedResponse else {
            fatalError("MockMovieRepository.mockedResponse não foi configurado.")
        }
        
        switch response {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}
