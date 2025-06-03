//
//  MovieRepositoryProtocol.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

protocol MovieRepositoryProtocol {
    func getPopularMovies(page: Int) async throws -> MovieApiResponse
    // MARK: TO DO
    // func getMovieDetails
    // func saveMoviesToCache
    // func getMoviesFromCache
}

