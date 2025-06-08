//
//  File.swift
//  MovieListAssessmentTests
//
//  Created by William Moraes da Silva on 03/06/25.
//

import XCTest
import Combine
@testable import MovieListAssessment

@MainActor
final class ImageLoaderViewModelTests: XCTestCase {
  var viewModel: ImageLoaderViewModel!
  var mockImageCache: MockImageCacheService!
  var cancellables: Set<AnyCancellable>!
  
  let testURL = URL(string: "https://example.com/image.jpg")!
  let sampleImage = UIImage(systemName: "star.fill") ?? UIImage()
  
  override func setUp() {
    super.setUp()
    mockImageCache = MockImageCacheService()
    cancellables = Set<AnyCancellable>()
  }
  
  override func tearDown() {
    viewModel = nil
    mockImageCache = nil
    cancellables = nil
    super.tearDown()
  }
  
  // imagem  carregada com sucesso
  func test_loadImage_success_updatesStateCorrectly() {
    // Arrange
    viewModel = ImageLoaderViewModel(url: testURL, imageCache: mockImageCache)
    mockImageCache.loadImagePublisher = Just(sampleImage) // síncrono, nao há delay, emite um unico valor e finaliza ( just one time )
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
    
    let imageExpectation = XCTestExpectation(description: "Imagem deve ser carregada") // crio expectaions, sem isso o testo assinc termina antes de acontecerem, "cria uma pausa" que deve ser atendida
    let isLoadingFalseExpectation = XCTestExpectation(description: "isLoading deve ser false no final")
    
    // garante ViewModel Limpa
    XCTAssertNil(viewModel.image, "Imagem inicial deve ser nil") // a imagem nao existe ainda
    XCTAssertFalse(viewModel.isLoading, "isLoading inicial deve ser false") // o loading nao esta rodando
    
    viewModel.$image
      .dropFirst() // ignora o valor inicial, so observa mudanças
      .sink { loadedImage in // se inscreve como listener
        if loadedImage != nil {
          XCTAssertEqual(loadedImage, self.sampleImage, "Imagem carregada não é a esperada") // confiro se a sampleImage passada é igual a que foi carregada
          imageExpectation.fulfill() // aviso que a imageExpectation foi cumprida
        }
      }
      .store(in: &cancellables) // evito memory leaks
    
    viewModel.$isLoading
      .dropFirst()
      .sink { isLoading in
        if !isLoading && self.viewModel.image != nil { // valido que quando a imagem existe, o loading nao existira
          isLoadingFalseExpectation.fulfill() // aviso que a imageExpectation foi cumprida
        }
      }
      .store(in: &cancellables)
    
    // Act
    viewModel.loadImage() // ativo o loadImage, os binds acimam são executadas
    
    // Assert (imediato)
    XCTAssertTrue(viewModel.isLoading, "isLoading deveria ser true imediatamente após chamar load")
    
    // Assert (assíncrono)
    wait(for: [imageExpectation, isLoadingFalseExpectation], timeout: 1.0) // aguardo 1 seg para que o test async finalize
    XCTAssertNil(viewModel.errorMessage, "errorMessage deveria ser nil em caso de sucesso")
    XCTAssertEqual(mockImageCache.loadImageCallCount, 1, "loadImage do cache deveria ser chamado uma vez")
    XCTAssertEqual(mockImageCache.lastURLLoaded, testURL, "URL passada para o cache não é a esperada")
  }
  
  // testando imagem  sem URL
  func test_loadImage_withNilURL_doesNotAttemptLoad() {
    // Arrange
    viewModel = ImageLoaderViewModel(url: nil, imageCache: mockImageCache)
    
    // Act
    viewModel.loadImage()
    
    // Assert
    XCTAssertFalse(viewModel.isLoading, "isLoading deveria permanecer false para URL nula")
    XCTAssertNil(viewModel.image, "Imagem deveria permanecer nil para URL nula")
    XCTAssertNil(viewModel.errorMessage, "errorMessage deveria permanecer nil para URL nula")
    XCTAssertEqual(mockImageCache.loadImageCallCount, 0, "loadImage do cache não deveria ser chamado para URL nula")
  }
  
  // url já esta sendo baixada, nao deve chamar novamente
  func test_loadImage_whenAlreadyLoading_doesNotStartNewLoad() {
    // Arrange
    viewModel = ImageLoaderViewModel(url: testURL, imageCache: mockImageCache)
    let neverCompletingPublisher = PassthroughSubject<UIImage, Error>().eraseToAnyPublisher() // nunca completa, pendente pra sempre
    mockImageCache.loadImagePublisher = neverCompletingPublisher
    
    viewModel.loadImage()
    XCTAssertTrue(viewModel.isLoading, "isLoading deveria ser true após a primeira chamada a load")
    XCTAssertEqual(mockImageCache.loadImageCallCount, 1, "loadImage do cache deveria ser chamado uma vez")
    
    // Act
    viewModel.loadImage()
    
    // Assert
    XCTAssertTrue(viewModel.isLoading, "isLoading ainda deveria ser true")
    XCTAssertEqual(mockImageCache.loadImageCallCount, 1, "loadImage do cache não deveria ser chamado novamente se já estiver carregando")
  }
  
  // a imagem já esta em cache, nao deve ser baixada novamente
  func test_loadImage_whenImageAlreadyLoaded_doesNotStartNewLoad() {
    // Arrange
    viewModel = ImageLoaderViewModel(url: testURL, imageCache: mockImageCache)
    viewModel.image = sampleImage // Simula que a imagem já foi carregada no ViewModel
    
    // Act
    viewModel.loadImage()
    
    // Assert
    XCTAssertFalse(viewModel.isLoading, "isLoading deveria ser false se a imagem já está carregada")
    XCTAssertEqual(viewModel.image, sampleImage, "Imagem original deveria permanecer")
    XCTAssertEqual(mockImageCache.loadImageCallCount, 0, "loadImage do cache não deveria ser chamado se a imagem já está carregada no ViewModel")
  }
}
