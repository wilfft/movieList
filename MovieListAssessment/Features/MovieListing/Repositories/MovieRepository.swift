//
//  Untitled.swift
//  MovieListAssessment
//
//  Created by William Moraes da Silva on 03/06/25.
//

import Foundation

// MARK: JUSTIFICATIVA
// Optei por uma estratégia de cache em memória para as requisiçoes com NSCache para melhorar a performance em acessos repetidos à mesma página de filmes dentro de uma sessão. A dependência do MovieAPIService é injetada via protocolo para testabilidade.

// MARK: TRADE OFFS
// O cache é volátil e não oferece suporte offline. A política de invalidação é apenas a do NSCache (baseada em limites/pressão de memória), sem expiração por tempo.
// não adequado para dados mto grandes
// caso algum novo filme entre pra lista e ja tiver a pagina em chache, o filme nao ira aparecer, somente apos limpar a lista.

// MARK: MELHORIAS
// Suporte Offline atraves de Persistenciia local: FileManager/CoreData/SwiftData/Realm
// ou até mesmo URLCache se a API suportar
// Políticas de Expiração-timestamp: Para garantir que os dados não fiquem muito tempo desatualizados.
// Estratégia Stale-While-Revalidate: Para balancear velocidade e dados recentes.
// Abstração da Camada de Cache: Para facilitar a troca de implementações de cache no futuro (DiskCacheService/InMemoryCacheService)
// Stale-While-Revalidate: mostro o cache enquanto faço a requisiçao
// tratamento de erro caso a api falhe, trazer o conteudo mesmo que antigo em cache
// Polling, periodicamente em background, nao mto bom pra listar mas sim para itens criticos.
// Push Notifications ou WebSockets (Avançado), API suportasse, notifica quando tem itens novos e invalida o que ja tem

final class MovieRepository: MovieRepositoryProtocol {
  private let apiService: MovieAPIServiceProtocol
  // estou usando um wrapper de uma classe para facilitar a armazenmeto, no futuro posso aplicar uma politica de timestamp por exemplo.
  
  //caso fosse cachear diferentes tipos de respsotas poderia usar uma Generic CachedItem<T>
  // MARK: IMPORTANTE, Deixar genérico CachedItem<T>
  private class CachedApiResponse {
    let response: MovieApiResponse
    
    init(_ response: MovieApiResponse) {
      self.response = response
    }
  }
  
  //NSCache, soluçao de cache em memória, gerencia automaticamente desalocaçao de obj sobre pressao de memoria.
  //thread safe, limite de contagem de tamanho
  //NSNumber para chave de pagina, exige classe para Chave e para conteudo

  private let memoryCache = NSCache<NSNumber, CachedApiResponse>()
  
  // Sendo injetado via construtor para favorecer testabilidade atracves de mock e e flexibilidade (Container, Coordiantor_
  init(apiService: MovieAPIServiceProtocol) {
    self.apiService = apiService
  }
  
  func getPopularMovies(page: Int) async throws -> MovieApiResponse {
    let pageKey = NSNumber(value: page) // a pagina que recebo sera a Key do objeto
    // limitaçao da chave pela pagina, caso tenha genero, nao consigo buscar
    
    // estrategia Cache-First
    if let cachedWrapper = memoryCache.object(forKey: pageKey) {
      print("Repositório: Carregando filmes da página \(page) do NSCache.")
      return cachedWrapper.response
    }
    
    // nao achou em cache, faz o download da api
    print("Repositório: Cache ausente para a página \(page). Buscando da API...")
    do {
      let apiResponse = try await apiService.fetchPopularMovies(page: page) // requisiçao asinc para trazer os filmes da devida pagina
       
      //armazena a response em um wrapper
      let newCachedWrapper = CachedApiResponse(apiResponse)
      memoryCache.setObject(newCachedWrapper, forKey: pageKey) // armazena em cache para ser usado posteriormente.
      
      print("Repositório: Filmes da página \(page) salvos no NSCache.")
      return apiResponse
    } catch {
      //tratamento de erro simples
      print("Repositório: Falha na rede ao buscar página \(page) e não há cache prévio.")
      throw error
    }
  }
  
  // não está sendo usado mas pode ser usado nos testes unitarios
  func clearCache() {
    memoryCache.removeAllObjects()
    print("Repositório: NSCache limpo.")
  }
}
