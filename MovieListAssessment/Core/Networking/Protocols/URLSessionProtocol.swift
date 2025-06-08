//
//  URLSessionProtocol.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 08/06/25.
//
import Foundation

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}
