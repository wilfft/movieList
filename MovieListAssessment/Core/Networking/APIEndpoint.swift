//
//  ApiEndpoint.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 08/06/25.
//

import Foundation

struct APIEndpoint {
  let path: String
  let method: HTTPMethod
  var queryParameters: [URLQueryItem]
  // var body: Data? //
  // var headers: [String: String]?
  
  init(path: String,
       method: HTTPMethod = .get,
       queryParameters: [URLQueryItem] = []) {
    self.path = path
    self.method = method
    self.queryParameters = queryParameters
  }
}
