//
//  File.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "A URL fornecida é inválida."
        case .networkError(let error):
            return "Erro de rede: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Erro ao decodificar os dados: \(error.localizedDescription)"
        case .apiError(let message):
            return "Erro da API: \(message)"
        case .unknown:
            return "Ocorreu um erro desconhecido."
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): return true
        case (.networkError, .networkError): return true
        case (.decodingError, .decodingError): return true
        case (.apiError(let lMsg), .apiError(let rMsg)): return lMsg == rMsg
        case (.unknown, .unknown): return true
        default: return false
        }
    }
}
