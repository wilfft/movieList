//
//  MovieAPIService.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Foundation

struct MovieAPIService: MovieAPIServiceProtocol {
  private let api: APIService
  private let defaultLanguage = "pt-BR"
  private let apiKey = AppConstants.tmdbApiKey
  
  init(api: APIService = APIService(baseURL: AppConstants.baseURL)) {
    self.api = api
  }
  
  func fetchPopularMovies(page: Int) async throws -> MovieApiResponse {
    var allQueryItems: [URLQueryItem] = []
    
    allQueryItems.append(URLQueryItem(name: "api_key", value: apiKey))
    allQueryItems.append(URLQueryItem(name: "language", value: defaultLanguage))
    allQueryItems.append(URLQueryItem(name: "page", value: "\(page)"))
    
    let endpoint = APIEndpoint(
      path: "/movie/popular",
      queryParameters: allQueryItems)
    
    return try await api.request(endpoint: endpoint, responseType: MovieApiResponse.self)
  }
}
