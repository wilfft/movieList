//
//  APIService.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 08/06/25.
//
import Foundation

final class APIService {
  private let session: URLSessionProtocol
  private let baseURL: String
  
  init(baseURL: String,
       session: URLSessionProtocol = URLSession.shared) {
    self.baseURL = baseURL
    self.session = session
  }
  
  func request<T: Decodable>(
    endpoint: APIEndpoint,
    responseType: T.Type
  ) async throws -> T {
    
    guard var components = URLComponents(string: baseURL) else {
      throw AppError.invalidURL
    }
    components.path += endpoint.path
    components.queryItems = endpoint.queryParameters
    
    guard let url = components.url else {
      throw AppError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method.rawValue
    
    do {
      let (data, response) = try await session.data(for: request)
      
      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        throw AppError.apiError("Erro HTTP")
      }
      
      return try JSONDecoder().decode(responseType, from: data)
      
    } catch let urlError as URLError {
      throw AppError.networkError(urlError)
    } catch {
      throw AppError.decodingError(error)
    }
  }
}
