//
//  File.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Foundation
import Combine
import UIKit

protocol ImageCacheServiceProtocol {
    func loadImage(from url: URL) -> AnyPublisher<UIImage, Error>
}
