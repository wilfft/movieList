//
//  Untitled.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 08/06/25.
//
import Foundation

extension APIEndpoint {
  static func popularMovies(page: Int) -> APIEndpoint {
      return APIEndpoint(
          path: "/movie/popular",
          method: .get,
          queryParameters: [URLQueryItem(name: "page", value: "\(page)")]
      )
  }
}
