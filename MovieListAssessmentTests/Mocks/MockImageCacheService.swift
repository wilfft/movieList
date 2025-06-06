//
//  Untitled.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import XCTest
import Combine

@testable import MovieListAssessment

final class MockImageCacheService: ImageCacheServiceProtocol {
    var loadImagePublisher: AnyPublisher<UIImage, Error>?
    var loadImageCallCount = 0
    var lastURLLoaded: URL?

    func loadImage(from url: URL) -> AnyPublisher<UIImage, Error> {
        loadImageCallCount += 1
        lastURLLoaded = url
        if let publisher = loadImagePublisher {
            return publisher
        }
        // Retornar um publisher que falha por padrão se não configurado
        return Fail(error: NSError(domain: "MockImageCacheService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Publisher não configurado"]))
            .eraseToAnyPublisher()
    }
}
