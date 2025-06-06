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
class ImageLoaderViewModelTests: XCTestCase {
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

    func test_loadImage_success_updatesStateCorrectly() {
        // Arrange
        viewModel = ImageLoaderViewModel(url: testURL, imageCache: mockImageCache)
        mockImageCache.loadImagePublisher = Just(sampleImage)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        let imageExpectation = XCTestExpectation(description: "Imagem deve ser carregada")
        let isLoadingFalseExpectation = XCTestExpectation(description: "isLoading deve ser false no final")
        
        XCTAssertNil(viewModel.image, "Imagem inicial deve ser nil")
        XCTAssertFalse(viewModel.isLoading, "isLoading inicial deve ser false")

        viewModel.$image
            .dropFirst()
            .sink { loadedImage in
                if loadedImage != nil {
                    XCTAssertEqual(loadedImage, self.sampleImage, "Imagem carregada não é a esperada")
                    imageExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                
                if !isLoading && self.viewModel.image != nil { // Garante que isLoading é false DEPOIS que a imagem foi setada
                    isLoadingFalseExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        viewModel.loadImage()

        // Assert (imediato)
        XCTAssertTrue(viewModel.isLoading, "isLoading deveria ser true imediatamente após chamar load")
        
        // Assert (assíncrono)
        wait(for: [imageExpectation, isLoadingFalseExpectation], timeout: 1.0)
        XCTAssertNil(viewModel.errorMessage, "errorMessage deveria ser nil em caso de sucesso")
        XCTAssertEqual(mockImageCache.loadImageCallCount, 1, "loadImage do cache deveria ser chamado uma vez")
        XCTAssertEqual(mockImageCache.lastURLLoaded, testURL, "URL passada para o cache não é a esperada")
    }

    // Teste 2: Falha no carregamento
    func test_loadImage_failure_updatesStateCorrectly() {
        // Arrange
        viewModel = ImageLoaderViewModel(url: testURL, imageCache: mockImageCache)
        let expectedError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Erro de rede simulado"])
        mockImageCache.loadImagePublisher = Fail(error: expectedError)
            .eraseToAnyPublisher()

        let errorMessageExpectation = XCTestExpectation(description: "errorMessage deve ser definido")
        let isLoadingFalseExpectation = XCTestExpectation(description: "isLoading deve ser false no final")

        // Observar mudanças
        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    XCTAssertEqual(errorMessage, "Falha: \(expectedError.localizedDescription)", "Mensagem de erro não é a esperada")
                    errorMessageExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                if !isLoading && self.viewModel.errorMessage != nil {
                    isLoadingFalseExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
            
        // Act
        viewModel.loadImage()

        // Assert (imediato)
        XCTAssertTrue(viewModel.isLoading)
        
        // Assert (assíncrono)
        wait(for: [errorMessageExpectation, isLoadingFalseExpectation], timeout: 1.0)
        XCTAssertNil(viewModel.image, "Imagem deveria ser nil em caso de falha")
        XCTAssertEqual(mockImageCache.loadImageCallCount, 1)
    }

    // Teste 3: URL nula
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

    // Teste 4: Tentar carregar quando já está carregando
    func test_loadImage_whenAlreadyLoading_doesNotStartNewLoad() {
        // Arrange
        viewModel = ImageLoaderViewModel(url: testURL, imageCache: mockImageCache)
        // Simula que um carregamento já está em andamento (publisher nunca completa)
        let neverCompletingPublisher = PassthroughSubject<UIImage, Error>().eraseToAnyPublisher()
        mockImageCache.loadImagePublisher = neverCompletingPublisher
        
        viewModel.loadImage() // Primeira chamada, isLoading se torna true
        XCTAssertTrue(viewModel.isLoading, "isLoading deveria ser true após a primeira chamada a load")
        XCTAssertEqual(mockImageCache.loadImageCallCount, 1, "loadImage do cache deveria ser chamado uma vez")

        // Act: Tenta carregar de novo enquanto o primeiro ainda está "em andamento"
        viewModel.loadImage()

        // Assert
        XCTAssertTrue(viewModel.isLoading, "isLoading ainda deveria ser true")
        XCTAssertEqual(mockImageCache.loadImageCallCount, 1, "loadImage do cache não deveria ser chamado novamente se já estiver carregando")
    }

    // Teste 5: Tentar carregar quando a imagem já foi carregada
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
    
    // Teste 6: Cancelamento
    func test_cancelLoading_resetsIsLoadingAndCancelsSubscription() {
        // Arrange
        viewModel = ImageLoaderViewModel(url: testURL, imageCache: mockImageCache)
        // Um publisher que permite controlar o cancelamento manualmente para o teste
        let subject = PassthroughSubject<UIImage, Error>()
        mockImageCache.loadImagePublisher = subject.eraseToAnyPublisher()

        var subscriptionCancelled = false
        let cancellable = viewModel.$isLoading // Apenas para ter algo para cancelar no teste, não ideal
            .sink(receiveCompletion: { completion in
                if case .finished = completion { // Este finished é do $isLoading, não do download
                    // Não é o melhor jeito de testar cancelamento do download aqui
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables) // Adiciona à lista
        
        // Inicia o carregamento
        viewModel.loadImage()
        XCTAssertTrue(viewModel.isLoading)

        // Act
        viewModel.cancelLoading()

        // Assert
        XCTAssertFalse(viewModel.isLoading, "isLoading deveria ser false após cancelar")
         
        subject.send(sampleImage)
        XCTAssertNil(viewModel.image, "Imagem não deveria ser setada se o carregamento foi cancelado antes do publisher emitir.")
    }
}
