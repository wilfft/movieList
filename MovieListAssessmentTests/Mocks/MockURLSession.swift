//
//  File.swift
//  MovieListAssessmentTests
//
//  Created by William Moraes da Silva on 08/06/25.
//

import Foundation
@testable import MovieListAssessment

final class MockURLSession: URLSessionProtocol {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    var dataTaskCallCount = 0
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        dataTaskCallCount += 1
        
        if let error = error {
            throw error
        }
        
        return (data ?? Data(), response ?? URLResponse())
    }
}
//
//struct MockEndpoint: APIEndpoint {
//    let path: String
//  let method: HTTPMethod = .get
//    let queryParameters: [URLQueryItem]?
//}
