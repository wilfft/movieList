import XCTest
import Combine
import UIKit
@testable import MovieListAssessment

final class ImageCacheServiceTests: XCTestCase {
    
    var imageCache: ImageCacheService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        // Criando uma instância própria para os testes (não usando o singleton)
        imageCache = ImageCacheService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        imageCache?.clearCache()
        imageCache = nil
        cancellables = nil
        super.tearDown()
    }
    
    // TESTE 1: Cache Hit - Imagem já está no cache
    func test_loadImage_cacheHit_returnsImageImmediately() {
        // Arrange
        let testURL = URL(string: "https://example.com/image.jpg")!
        let testImage = createTestImage()
        
        // Pré-carrega a imagem no cache
        imageCache.setImage(testImage, forKey: testURL)
        
        let expectation = XCTestExpectation(description: "Image should be returned from cache")
        
        // Act
        imageCache.loadImage(from: testURL)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Não deveria falhar: \(error)")
                    }
                },
                receiveValue: { image in
                    // Assert
                    XCTAssertNotNil(image)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // TESTE 2: Cache Miss - Baixa da internet
    func test_loadImage_cacheMiss_downloadsFromNetwork() {
        // Arrange
        let testURL = URL(string: "https://httpbin.org/image/png")! // URL que retorna imagem real
        let expectation = XCTestExpectation(description: "Image should be downloaded")
        
        // Act
        imageCache.loadImage(from: testURL)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Download falhou: \(error)")
                    }
                },
                receiveValue: { image in
                    // Assert
                    XCTAssertNotNil(image)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // TESTE 3: Requisições duplicadas - Deve retornar o mesmo publisher
    func test_loadImage_duplicateRequests_sharesSamePublisher() {
        // Arrange
        let testURL = URL(string: "https://httpbin.org/delay/2")! // URL com delay
        let expectation1 = XCTestExpectation(description: "First request completes")
        let expectation2 = XCTestExpectation(description: "Second request completes")
        
        var firstResult: UIImage?
        var secondResult: UIImage?
        
        // Act - Fazendo duas requisições simultâneas
        imageCache.loadImage(from: testURL)
            .sink(
                receiveCompletion: { _ in expectation1.fulfill() },
                receiveValue: { image in firstResult = image }
            )
            .store(in: &cancellables)
        
        imageCache.loadImage(from: testURL)
            .sink(
                receiveCompletion: { _ in expectation2.fulfill() },
                receiveValue: { image in secondResult = image }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation1, expectation2], timeout: 10.0)
        
        // Assert
        XCTAssertNotNil(firstResult)
        XCTAssertNotNil(secondResult)
        // Verifica se ambos receberam a mesma imagem (mesmo publisher)
        XCTAssertEqual(firstResult?.pngData(), secondResult?.pngData())
    }
    
    // TESTE 4: URL inválida - Deve falhar
    func test_loadImage_invalidURL_fails() {
        // Arrange
        let testURL = URL(string: "https://invalid-url-that-doesnt-exist.com/image.jpg")!
        let expectation = XCTestExpectation(description: "Should fail with error")
        
        // Act
        imageCache.loadImage(from: testURL)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        expectation.fulfill() // Sucesso - erro esperado
                    }
                },
                receiveValue: { _ in
                    XCTFail("Não deveria retornar imagem para URL inválida")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // TESTE 5: Clear cache - Remove todas as imagens
    func test_clearCache_removesAllCachedImages() {
        // Arrange
        let testURL1 = URL(string: "https://example.com/image1.jpg")!
        let testURL2 = URL(string: "https://example.com/image2.jpg")!
        let testImage = createTestImage()
        
        // Pré-carrega imagens no cache
        imageCache.setImage(testImage, forKey: testURL1)
        imageCache.setImage(testImage, forKey: testURL2)
        
        // Verifica que estão no cache
        XCTAssertNotNil(imageCache.getImage(forKey: testURL1))
        XCTAssertNotNil(imageCache.getImage(forKey: testURL2))
        
        // Act
        imageCache.clearCache()
        
        // Assert
        XCTAssertNil(imageCache.getImage(forKey: testURL1))
        XCTAssertNil(imageCache.getImage(forKey: testURL2))
    }
    
    // TESTE 6: Thread Safety - Múltiplas threads acessando simultaneamente
    func test_loadImage_threadSafety_handlesMultipleThreads() {
        // Arrange
        let testURL = URL(string: "https://httpbin.org/image/png")!
        let expectation = XCTestExpectation(description: "All threads complete")
        expectation.expectedFulfillmentCount = 5
        
        // Act - Fazendo 5 requisições em threads diferentes
        for i in 0..<5 {
            DispatchQueue.global(qos: .background).async {
                self.imageCache.loadImage(from: testURL)
                    .sink(
                        receiveCompletion: { _ in
                            expectation.fulfill()
                        },
                        receiveValue: { image in
                            XCTAssertNotNil(image, "Thread \(i) should receive image")
                        }
                    )
                    .store(in: &self.cancellables)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 100, height: 100))
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - Extensão para tornar métodos privados testáveis
extension ImageCacheService {
    func getImage(forKey key: URL) -> UIImage? {
        return memoryCache.object(forKey: key as NSURL)?.image
    }
    
    func setImage(_ image: UIImage, forKey key: URL) {
        let cachedItem = CachedImageItem(image)
        let cost = image.pngData()?.count ?? 0
        memoryCache.setObject(cachedItem, forKey: key as NSURL, cost: cost)
    }
}
