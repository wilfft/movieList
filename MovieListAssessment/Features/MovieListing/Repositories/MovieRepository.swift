//
//  Untitled.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Foundation

final class MovieRepository: MovieRepositoryProtocol {
  private let apiService: MovieAPIServiceProtocol
  
  private class CachedApiResponse {
    let response: MovieApiResponse
    init(_ response: MovieApiResponse) {
      self.response = response
    }
  }
  
  private let memoryCache = NSCache<NSNumber, CachedApiResponse>()
  
  init(apiService: MovieAPIServiceProtocol) {
    self.apiService = apiService
  }
  
  func getPopularMovies(page: Int) async throws -> MovieApiResponse {
         let pageKey = NSNumber(value: page)

         if let cachedWrapper = memoryCache.object(forKey: pageKey) {
             print("Repositório: Carregando filmes da página \(page) do NSCache.")
             return cachedWrapper.response
         }

         print("Repositório: Cache miss para a página \(page). Buscando da API...")
         do {
             let apiResponse = try await apiService.fetchPopularMovies(page: page)
              
             let newCachedWrapper = CachedApiResponse(apiResponse)
             memoryCache.setObject(newCachedWrapper, forKey: pageKey)
             
             print("Repositório: Filmes da página \(page) salvos no NSCache.")
             
             return apiResponse
         } catch {
            
             print("Repositório: Falha na rede ao buscar página \(page) e não havia cache prévio.")
             throw error
         }
     }
  
      func clearCache() {
          memoryCache.removeAllObjects()
          print("Repositório: NSCache limpo.")
      }
}
