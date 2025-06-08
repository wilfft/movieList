//
//  APIService.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 08/06/25.
//
import Foundation

// Generico para chamadas pra API
// nao tem conhecimento da api de Movie, posso reutilizar em outros projetos
// Reusabilidade - (Princípio da Responsabilidade Única) Aprimorado:

final class APIService {
  private let session: URLSessionProtocol
  private let baseURL: String
  
  // posso mockar URLSessionProtocol
  init(baseURL: String,
       session: URLSessionProtocol = URLSession.shared) {
    self.baseURL = baseURL
    self.session = session
  }
  
  // adicionar um Request para enviar no body
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
