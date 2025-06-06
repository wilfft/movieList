//
//  MovieRowView.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import SwiftUI

struct MovieRowView: View {
    let movie: Movie

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
          
          CachedAsyncImageView(url: movie.posterURL) {
                ZStack {
                    Color.gray.opacity(0.1)
                    ProgressView()
                }
                .frame(width: 80, height: 120)
                .cornerRadius(8)
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: 80, height: 120)
            .clipped()
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)
                Text("Avaliação: \(String(format: "%.1f", movie.voteAverage))/10")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(movie.overview)
                    .font(.caption)
                    .lineLimit(3)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct MovieListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockMovie = Movie(id: 1, title: "Filme de Teste Muito Longo para Ver o Line Limit", overview: "Esta é uma visão geral de um filme de teste que tem um texto um pouco mais longo para que possamos ver como o line limit se comporta em diferentes situações.", posterPath: "/q coinvolackwDBh7D53u54MhPaG563.jpg", voteAverage: 7.5)
        let mockViewModel = MovieListViewModel(repository: MockMovieRepository(mockedResponse: .success(
            MovieApiResponse(page: 1, results: [mockMovie, mockMovie, mockMovie], totalPages: 1, totalResults: 3)
        )))
      
        return MovieListView(viewModel: mockViewModel)
    }
}

