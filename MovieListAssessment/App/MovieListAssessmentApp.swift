//
//  MovieListAssessmentApp.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import SwiftUI

@main
struct MovieListAssessmentApp: App {
    var body: some Scene {
        WindowGroup {
          MovieListView(viewModel: MovieListViewModel())
        }
    }
}
