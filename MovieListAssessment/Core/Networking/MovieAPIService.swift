//
//  r.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Foundation

final class MovieAPIService: MovieAPIServiceProtocol {
  
  private let apiKey = AppConstants.tmdbApiKey
  private let baseURL = "https://api.themoviedb.org/3"
  private let session: URLSession
  
  init(session: URLSession = .shared) {
    self.session = session
  }
  
  func fetchPopularMovies(page: Int) async throws -> MovieApiResponse {
    print("AQUI")
    print(apiKey)
    let urlString = "\(baseURL)/movie/popular?api_key=\(apiKey)&language=pt-BR&page=\(page)"
    guard let url = URL(string: urlString) else {
      throw AppError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    do {
      let (data, response) = try await session.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw AppError.unknown
      }
      
      guard (200...299).contains(httpResponse.statusCode) else {
        
        throw AppError.apiError("Erro HTTP: \(httpResponse.statusCode)")
      }
      
      do {
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(MovieApiResponse.self, from: data)
        return apiResponse
      } catch {
        throw AppError.decodingError(error)
      }
    } catch let error as AppError {
      throw error
    } catch {
      throw AppError.networkError(error)
    }
  }
}
