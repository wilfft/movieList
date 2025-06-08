import XCTest
import Foundation
@testable import MovieListAssessment

final class APIServiceTests: XCTestCase {
    
    var apiService: APIService!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        apiService = APIService(baseURL: "https://api.test.com", session: mockURLSession)
    }
    
    override func tearDown() {
        apiService = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    // TESTE 1: Sucesso - Resposta válida
    func test_request_success_returnsDecodedObject() async throws {
        // Arrange
        let expectedMovie = Movie(id: 1, title: "Test Movie", overview: "Test", posterPath: nil, voteAverage: 8.0)
        let responseData = try JSONEncoder().encode(expectedMovie)
        
        mockURLSession.data = responseData
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let endpoint = APIEndpoint(path: "/movie", queryParameters: [])
        
        // Act
        let result = try await apiService.request(endpoint: endpoint, responseType: Movie.self)
        
        // Assert
        XCTAssertEqual(result.id, expectedMovie.id)
        XCTAssertEqual(result.title, expectedMovie.title)
        XCTAssertEqual(mockURLSession.dataTaskCallCount, 1)
    }
    
    // TESTE 2: URL inválida
    func test_request_invalidBaseURL_throwsInvalidURLError() async {
        // Arrange
        apiService = APIService(baseURL: "invalid-url", session: mockURLSession)
        let endpoint = APIEndpoint(path: "/test", queryParameters: [])
        
        // Act & Assert
        do {
            _ = try await apiService.request(endpoint: endpoint, responseType: Movie.self)
            XCTFail("Deveria ter lançado AppError.invalidURL")
        } catch AppError.invalidURL {
            // Sucesso - erro esperado
        } catch {
            XCTFail("Erro inesperado: \(error)")
        }
    }
    
    // TESTE 3: Erro HTTP (status 404)
    func test_request_httpError_throwsAPIError() async {
        // Arrange
        mockURLSession.data = Data()
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        
        let endpoint = APIEndpoint(path: "/movie", queryParameters: [])
        
        // Act & Assert
        do {
            _ = try await apiService.request(endpoint: endpoint, responseType: Movie.self)
            XCTFail("Deveria ter lançado AppError.apiError")
        } catch AppError.apiError(let message) {
            XCTAssertEqual(message, "Erro HTTP")
        } catch {
            XCTFail("Erro inesperado: \(error)")
        }
    }
    
    // TESTE 5: Erro de decodificação
    func test_request_invalidJSON_throwsDecodingError() async {
        // Arrange
        let invalidJSON = "invalid json data".data(using: .utf8)!
        mockURLSession.data = invalidJSON
        mockURLSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let endpoint = APIEndpoint(path: "/movie", queryParameters: [])
        
        // Act & Assert
        do {
            _ = try await apiService.request(endpoint: endpoint, responseType: Movie.self)
            XCTFail("Deveria ter lançado AppError.decodingError")
        } catch AppError.decodingError {
            // Sucesso - erro esperado
        } catch {
            XCTFail("Erro inesperado: \(error)")
        }
    }
}
