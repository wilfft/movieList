//
//  Untitled.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import SwiftUI

struct MovieRowView: View {
    let movie: Movie

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
          
            // Usar nossa CachedAsyncImageView
          CachedAsyncImageView(url: movie.posterURL) {
                // Placeholder customizado para a imagem do filme
                ZStack {
                    Color.gray.opacity(0.1) // Fundo do placeholder
                    ProgressView()
                }
                .frame(width: 80, height: 120) // Defina o frame no placeholder
                .cornerRadius(8)
            }
            .aspectRatio(contentMode: .fill) // Aplica à imagem carregada
            .frame(width: 80, height: 120)   // Frame final da view da imagem
            .clipped()
            .cornerRadius(8)
            // .shadow(radius: 2) // Opcional: adicionar uma sombra leve

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

// Preview para MovieListView
struct MovieListView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview com dados mockados
        let mockMovie = Movie(id: 1, title: "Filme de Teste Muito Longo para Ver o Line Limit", overview: "Esta é uma visão geral de um filme de teste que tem um texto um pouco mais longo para que possamos ver como o line limit se comporta em diferentes situações.", posterPath: "/q coinvolackwDBh7D53u54MhPaG563.jpg", voteAverage: 7.5)
        let mockViewModel = MovieListViewModel(repository: MockMovieRepository(mockedResponse: .success(
            MovieApiResponse(page: 1, results: [mockMovie, mockMovie, mockMovie], totalPages: 1, totalResults: 3)
        )))
      
        return MovieListView(viewModel: mockViewModel)
    }
}

