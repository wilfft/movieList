//
//  MovieAPIServiceProtocol.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Foundation

protocol MovieAPIServiceProtocol {
    func fetchPopularMovies(page: Int) async throws -> MovieApiResponse
}
