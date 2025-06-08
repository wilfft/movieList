//
//  Untitled.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Foundation

struct AppConstants {
  static var tmdbApiKey: String {
    guard let infoDictionary = Bundle.main.infoDictionary else {
      fatalError("Info.plist não encontrado. Isso não deveria acontecer.")
    }
    
    guard let apiKey = infoDictionary["TMDB_API_KEY"] as? String else {
      fatalError("A chave 'TMDB_API_KEY' não foi encontrada no Info.plist ou não é uma String. Verifique sua configuração.")
    }
    
    return apiKey
  }
  
  static let baseURL = "https://api.themoviedb.org/3"
}
