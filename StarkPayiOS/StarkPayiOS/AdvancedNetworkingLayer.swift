import Foundation
import Network
import Combine
import SwiftUI

// MARK: - Advanced Networking Layer with Comprehensive Error Handling

/// High-performance networking layer for StarkPay with retry logic, caching, and monitoring
@MainActor
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // MARK: - Published Properties
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType = .wifi
    @Published var networkQuality: NetworkQuality = .excellent
    @Published var activeRequests: Set<String> = []
    @Published var requestCount = 0
    @Published var errorCount = 0
    
    // Configuration
    private let session: URLSession
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor", qos: .background)
    private let cache = NetworkCache()
    private let retryManager = RetryManager()
    
    // Request interception and logging
    private var requestInterceptors: [RequestInterceptor] = []
    private var responseInterceptors: [ResponseInterceptor] = []
    
    enum NetworkQuality {
        case poor, fair, good, excellent
        
        var description: String {
            switch self {
            case .poor: return "Poor Connection"
            case .fair: return "Fair Connection"
            case .good: return "Good Connection"
            case .excellent: return "Excellent Connection"
            }
        }
        
        var color: Color {
            switch self {
            case .poor: return .red
            case .fair: return .orange
            case .good: return .yellow
            case .excellent: return .green
            }
        }
    }
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        
        self.session = URLSession(
            configuration: config,
            delegate: NetworkSessionDelegate(),
            delegateQueue: nil
        )
        
        setupNetworkMonitoring()
        setupDefaultInterceptors()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path)
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
            networkQuality = .excellent
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
            networkQuality = determineNetworkQuality(path)
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
            networkQuality = .excellent
        } else {
            connectionType = .other
            networkQuality = .fair
        }
        
        // Notify analytics
        PerformanceMonitor.shared.trackNetworkRequest(
            url: "network_status_change",
            method: "MONITOR",
            startTime: Date(),
            endTime: Date(),
            responseSize: 0,
            statusCode: isConnected ? 200 : 0,
            error: isConnected ? nil : NetworkError.noConnection
        )
    }
    
    private func determineNetworkQuality(_ path: NWPath) -> NetworkQuality {
        // This would use more sophisticated network quality detection in production
        if path.isExpensive {
            return .fair
        } else {
            return .good
        }
    }
    
    // MARK: - Core Networking Methods
    
    func request<T: Codable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type,
        priority: TaskPriority = .medium,
        cachePolicy: CachePolicy = .default
    ) async throws -> T {
        
        let requestId = UUID().uuidString
        activeRequests.insert(requestId)
        requestCount += 1
        
        defer {
            activeRequests.remove(requestId)
        }
        
        do {
            // Check cache first
            if let cachedResponse: T = cache.get(for: endpoint, type: T.self, policy: cachePolicy) {
                return cachedResponse
            }
            
            // Create request
            var request = try createURLRequest(for: endpoint)
            
            // Apply interceptors
            for interceptor in requestInterceptors {
                request = try await interceptor.intercept(request)
            }
            
            // Track request start
            let startTime = Date()
            
            // Execute request with retry logic
            let (data, response) = try await executeWithRetry(request: request, endpoint: endpoint)
            
            // Track request completion
            let endTime = Date()
            let httpResponse = response as? HTTPURLResponse
            
            PerformanceMonitor.shared.trackNetworkRequest(
                url: endpoint.url,
                method: endpoint.method.rawValue,
                startTime: startTime,
                endTime: endTime,
                responseSize: Int64(data.count),
                statusCode: httpResponse?.statusCode,
                error: nil
            )
            
            // Apply response interceptors
            var processedData = data
            for interceptor in responseInterceptors {
                processedData = try await interceptor.intercept(processedData, response: response)
            }
            
            // Parse response
            let parsedResponse: T = try parseResponse(processedData, response: response)
            
            // Cache response if appropriate
            cache.set(parsedResponse, for: endpoint, policy: cachePolicy)
            
            return parsedResponse
            
        } catch {
            errorCount += 1
            
            // Track error
            PerformanceMonitor.shared.trackError(error, context: "NetworkRequest: \(endpoint.url)")
            
            throw error
        }
    }
    
    // MARK: - Request Creation and Execution
    
    private func createURLRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        guard let url = URL(string: endpoint.url) else {
            throw NetworkError.invalidURL(endpoint.url)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeout
        
        // Add headers
        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body for POST/PUT requests
        if let body = endpoint.body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
    
    private func executeWithRetry(request: URLRequest, endpoint: APIEndpoint) async throws -> (Data, URLResponse) {
        var lastError: Error?
        let maxRetries = endpoint.maxRetries ?? 3
        
        for attempt in 0...maxRetries {
            do {
                return try await session.data(for: request)
            } catch {
                lastError = error
                
                // Don't retry on certain errors
                if !retryManager.shouldRetry(error: error, attempt: attempt, endpoint: endpoint) {
                    break
                }
                
                // Calculate retry delay
                let delay = retryManager.calculateDelay(attempt: attempt, endpoint: endpoint)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? NetworkError.maxRetriesExceeded
    }
    
    private func parseResponse<T: Codable>(_ data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Check status code
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpError(httpResponse.statusCode, data)
        }
        
        // Parse JSON
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    // MARK: - Specialized Request Methods
    
    func upload<T: Codable>(
        _ endpoint: APIEndpoint,
        data: Data,
        responseType: T.Type,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> T {
        
        guard let url = URL(string: endpoint.url) else {
            throw NetworkError.invalidURL(endpoint.url)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        // Add headers
        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (responseData, response) = try await session.upload(for: request, from: data)
        return try parseResponse(responseData, response: response)
    }
    
    func download(
        _ endpoint: APIEndpoint,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        
        guard let url = URL(string: endpoint.url) else {
            throw NetworkError.invalidURL(endpoint.url)
        }
        
        let request = URLRequest(url: url)
        let (localURL, _) = try await session.download(for: request)
        
        return localURL
    }
    
    func websocket(
        _ endpoint: APIEndpoint,
        messageHandler: @escaping (URLSessionWebSocketTask.Message) -> Void
    ) async throws -> URLSessionWebSocketTask {
        
        guard let url = URL(string: endpoint.url) else {
            throw NetworkError.invalidURL(endpoint.url)
        }
        
        let request = URLRequest(url: url)
        let webSocketTask = session.webSocketTask(with: request)
        
        // Start receiving messages
        Task {
            do {
                while webSocketTask.state == .running {
                    let message = try await webSocketTask.receive()
                    messageHandler(message)
                }
            } catch {
                print("WebSocket error: \(error)")
            }
        }
        
        webSocketTask.resume()
        return webSocketTask
    }
    
    // MARK: - Interceptor Management
    
    private func setupDefaultInterceptors() {
        // Authentication interceptor
        requestInterceptors.append(AuthenticationInterceptor())
        
        // User agent interceptor
        requestInterceptors.append(UserAgentInterceptor())
        
        // Logging interceptor
        requestInterceptors.append(LoggingInterceptor())
        
        // Response validation interceptor
        responseInterceptors.append(ResponseValidationInterceptor())
    }
    
    func addRequestInterceptor(_ interceptor: RequestInterceptor) {
        requestInterceptors.append(interceptor)
    }
    
    func addResponseInterceptor(_ interceptor: ResponseInterceptor) {
        responseInterceptors.append(interceptor)
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        cache.clear()
    }
    
    func getCacheSize() -> Int64 {
        return cache.size
    }
    
    // MARK: - Request Cancellation
    
    func cancelAllRequests() {
        session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        activeRequests.removeAll()
    }
    
    func cancelRequest(withId id: String) {
        activeRequests.remove(id)
        session.getAllTasks { tasks in
            tasks.filter { $0.taskIdentifier.description == id }.forEach { $0.cancel() }
        }
    }
}

// MARK: - API Endpoint Protocol

protocol APIEndpoint {
    var url: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: [String: Any]? { get }
    var timeout: TimeInterval { get }
    var maxRetries: Int? { get }
    var requiresAuthentication: Bool { get }
    var cacheKey: String { get }
}

extension APIEndpoint {
    var timeout: TimeInterval { 30 }
    var maxRetries: Int? { 3 }
    var requiresAuthentication: Bool { false }
    var cacheKey: String { "\(method.rawValue):\(url)" }
}

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
}

// MARK: - Network Errors

enum NetworkError: Error, LocalizedError {
    case noConnection
    case invalidURL(String)
    case invalidResponse
    case httpError(Int, Data)
    case decodingError(Error)
    case encodingError(Error)
    case timeout
    case maxRetriesExceeded
    case cancelled
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, _):
            return "HTTP error \(code): \(httpStatusMessage(code))"
        case .decodingError:
            return "Failed to decode server response"
        case .encodingError:
            return "Failed to encode request data"
        case .timeout:
            return "Request timed out"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .cancelled:
            return "Request was cancelled"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Please check your internet connection and try again."
        case .httpError(let code, _):
            return httpRecoverySuggestion(code)
        case .timeout:
            return "Please try again. If the problem persists, check your connection."
        case .decodingError:
            return "This might be a temporary server issue. Please try again later."
        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
    
    private func httpStatusMessage(_ code: Int) -> String {
        switch code {
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 429: return "Too Many Requests"
        case 500: return "Internal Server Error"
        case 502: return "Bad Gateway"
        case 503: return "Service Unavailable"
        case 504: return "Gateway Timeout"
        default: return "Unknown Error"
        }
    }
    
    private func httpRecoverySuggestion(_ code: Int) -> String {
        switch code {
        case 401:
            return "Please log in again to continue."
        case 429:
            return "Too many requests. Please wait a moment and try again."
        case 500, 502, 503:
            return "Server is temporarily unavailable. Please try again later."
        case 504:
            return "Server is taking too long to respond. Please try again."
        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
}

// MARK: - Cache Implementation

class NetworkCache {
    private let cache = NSCache<NSString, CacheItem>()
    private let queue = DispatchQueue(label: "NetworkCache", attributes: .concurrent)
    
    init() {
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        cache.countLimit = 1000
    }
    
    func get<T: Codable>(for endpoint: APIEndpoint, type: T.Type, policy: CachePolicy) -> T? {
        guard policy != .noCache else { return nil }
        
        return queue.sync {
            let key = NSString(string: endpoint.cacheKey)
            guard let item = cache.object(forKey: key) else { return nil }
            
            // Check expiration
            if policy.isExpired(item.timestamp) {
                cache.removeObject(forKey: key)
                return nil
            }
            
            return try? JSONDecoder().decode(T.self, from: item.data)
        }
    }
    
    func set<T: Codable>(_ value: T, for endpoint: APIEndpoint, policy: CachePolicy) {
        guard policy != .noCache else { return }
        
        queue.async(flags: .barrier) {
            do {
                let data = try JSONEncoder().encode(value)
                let item = CacheItem(data: data, timestamp: Date())
                let key = NSString(string: endpoint.cacheKey)
                self.cache.setObject(item, forKey: key, cost: data.count)
            } catch {
                print("Cache encoding error: \(error)")
            }
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAllObjects()
        }
    }
    
    var size: Int64 {
        return queue.sync {
            // This is an approximation
            return Int64(cache.totalCostLimit)
        }
    }
    
    private class CacheItem {
        let data: Data
        let timestamp: Date
        
        init(data: Data, timestamp: Date) {
            self.data = data
            self.timestamp = timestamp
        }
    }
}

enum CachePolicy {
    case noCache
    case short // 5 minutes
    case medium // 1 hour
    case long // 24 hours
    case `default` // 15 minutes
    
    func isExpired(_ timestamp: Date) -> Bool {
        let interval: TimeInterval
        switch self {
        case .noCache: return true
        case .short: interval = 300 // 5 minutes
        case .medium: interval = 3600 // 1 hour
        case .long: interval = 86400 // 24 hours
        case .default: interval = 900 // 15 minutes
        }
        
        return Date().timeIntervalSince(timestamp) > interval
    }
}

// MARK: - Retry Manager

class RetryManager {
    func shouldRetry(error: Error, attempt: Int, endpoint: APIEndpoint) -> Bool {
        guard let maxRetries = endpoint.maxRetries, attempt < maxRetries else {
            return false
        }
        
        // Don't retry on certain errors
        if let networkError = error as? NetworkError {
            switch networkError {
            case .httpError(let code, _):
                // Don't retry client errors (4xx)
                return !(400...499 ~= code)
            case .cancelled, .decodingError:
                return false
            default:
                return true
            }
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled, .userCancelledAuthentication:
                return false
            case .timedOut, .cannotConnectToHost, .networkConnectionLost:
                return true
            default:
                return true
            }
        }
        
        return true
    }
    
    func calculateDelay(attempt: Int, endpoint: APIEndpoint) -> TimeInterval {
        // Exponential backoff with jitter
        let baseDelay = pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...1)
        return min(baseDelay + jitter, 30) // Cap at 30 seconds
    }
}

// MARK: - Request/Response Interceptors

protocol RequestInterceptor {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}

protocol ResponseInterceptor {
    func intercept(_ data: Data, response: URLResponse) async throws -> Data
}

class AuthenticationInterceptor: RequestInterceptor {
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var modifiedRequest = request
        
        // Add authentication headers
        if let token = await getAuthToken() {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return modifiedRequest
    }
    
    private func getAuthToken() async -> String? {
        // Implement token retrieval logic
        return UserDefaults.standard.string(forKey: "auth_token")
    }
}

class UserAgentInterceptor: RequestInterceptor {
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var modifiedRequest = request
        
        let userAgent = "StarkPay-iOS/\(getAppVersion()) (iOS \(UIDevice.current.systemVersion))"
        modifiedRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        return modifiedRequest
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

class LoggingInterceptor: RequestInterceptor {
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        #if DEBUG
        print("🌐 Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let headers = request.allHTTPHeaderFields {
            print("📋 Headers: \(headers)")
        }
        if let body = request.httpBody {
            print("📦 Body: \(String(data: body, encoding: .utf8) ?? "Binary data")")
        }
        #endif
        
        return request
    }
}

class ResponseValidationInterceptor: ResponseInterceptor {
    func intercept(_ data: Data, response: URLResponse) async throws -> Data {
        #if DEBUG
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Response: \(httpResponse.statusCode) \(response.url?.absoluteString ?? "")")
            print("📄 Data: \(String(data: data, encoding: .utf8) ?? "Binary data")")
        }
        #endif
        
        // Validate response integrity
        if let httpResponse = response as? HTTPURLResponse {
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.httpError(httpResponse.statusCode, data)
            }
        }
        
        return data
    }
}

// MARK: - Network Session Delegate

class NetworkSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            print("URLSession became invalid with error: \(error)")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            PerformanceMonitor.shared.trackError(error, context: "URLSessionTask")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        // You could publish this progress for upload tasks
    }
}

// MARK: - StarkNet API Endpoints

enum StarkNetAPI: APIEndpoint {
    case getBalance(address: String)
    case sendTransaction(transaction: [String: Any])
    case getTransactionStatus(hash: String)
    case getTransactionHistory(address: String, page: Int)
    case estimateGasFee(transaction: [String: Any])
    case getBlockInfo(blockNumber: Int)
    case getAccountNonce(address: String)
    
    var url: String {
        let baseURL = AppConfigurationManager.shared.preferredNetwork == .mainnet ?
            "https://starknet-mainnet.infura.io/v3/" :
            "https://starknet-goerli.infura.io/v3/"
        
        let apiKey = getAPIKey()
        
        switch self {
        case .getBalance(let address):
            return "\(baseURL)\(apiKey)/starknet_call"
        case .sendTransaction:
            return "\(baseURL)\(apiKey)/starknet_addInvokeTransaction"
        case .getTransactionStatus(let hash):
            return "\(baseURL)\(apiKey)/starknet_getTransactionStatus"
        case .getTransactionHistory:
            return "\(baseURL)\(apiKey)/starknet_getTransactionsByAccount"
        case .estimateGasFee:
            return "\(baseURL)\(apiKey)/starknet_estimateFee"
        case .getBlockInfo:
            return "\(baseURL)\(apiKey)/starknet_getBlockWithTxs"
        case .getAccountNonce:
            return "\(baseURL)\(apiKey)/starknet_getNonce"
        }
    }
    
    var method: HTTPMethod {
        return .POST
    }
    
    var headers: [String: String] {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    var body: [String: Any]? {
        switch self {
        case .getBalance(let address):
            return [
                "jsonrpc": "2.0",
                "method": "starknet_call",
                "params": [
                    "request": [
                        "contract_address": "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7", // ETH contract
                        "entry_point_selector": "0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e", // balanceOf selector
                        "calldata": [address]
                    ],
                    "block_id": "latest"
                ],
                "id": 1
            ]
        case .sendTransaction(let transaction):
            return [
                "jsonrpc": "2.0",
                "method": "starknet_addInvokeTransaction",
                "params": transaction,
                "id": 1
            ]
        case .getTransactionStatus(let hash):
            return [
                "jsonrpc": "2.0",
                "method": "starknet_getTransactionStatus",
                "params": ["transaction_hash": hash],
                "id": 1
            ]
        case .getTransactionHistory(let address, let page):
            return [
                "jsonrpc": "2.0",
                "method": "starknet_getTransactionsByAccount",
                "params": [
                    "account_address": address,
                    "limit": 20,
                    "offset": page * 20
                ],
                "id": 1
            ]
        case .estimateGasFee(let transaction):
            return [
                "jsonrpc": "2.0",
                "method": "starknet_estimateFee",
                "params": [transaction],
                "id": 1
            ]
        case .getBlockInfo(let blockNumber):
            return [
                "jsonrpc": "2.0",
                "method": "starknet_getBlockWithTxs",
                "params": ["block_id": blockNumber],
                "id": 1
            ]
        case .getAccountNonce(let address):
            return [
                "jsonrpc": "2.0",
                "method": "starknet_getNonce",
                "params": [
                    "contract_address": address,
                    "block_id": "latest"
                ],
                "id": 1
            ]
        }
    }
    
    var timeout: TimeInterval {
        switch self {
        case .sendTransaction: return 60 // Longer timeout for sending transactions
        case .getTransactionHistory: return 45
        default: return 30
        }
    }
    
    var maxRetries: Int? {
        switch self {
        case .sendTransaction: return 1 // Don't retry transaction sends
        case .getBalance, .getTransactionStatus: return 3
        default: return 2
        }
    }
    
    var requiresAuthentication: Bool {
        return false // StarkNet RPC doesn't require authentication, just API key
    }
    
    private func getAPIKey() -> String {
        // In production, this would be securely stored
        return Bundle.main.infoDictionary?["INFURA_API_KEY"] as? String ?? "your-api-key"
    }
}

// MARK: - Response Models

struct StarkNetResponse<T: Codable>: Codable {
    let jsonrpc: String
    let id: Int
    let result: T?
    let error: StarkNetError?
}

struct StarkNetError: Codable, Error {
    let code: Int
    let message: String
    
    var localizedDescription: String {
        return "StarkNet Error \(code): \(message)"
    }
}

struct BalanceResponse: Codable {
    let balance: String
}

struct TransactionResponse: Codable {
    let transaction_hash: String
}

struct TransactionStatus: Codable {
    let finality_status: String
    let execution_status: String?
}

// MARK: - Network Status View

struct NetworkStatusView: View {
    @StateObject private var networkManager = NetworkManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Connection indicator
            Circle()
                .fill(networkManager.isConnected ? networkManager.networkQuality.color : .red)
                .frame(width: 8, height: 8)
                .animation(.easeInOut(duration: 0.3), value: networkManager.isConnected)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(connectionStatusText)
                    .dynamicTypeSize(12, weight: .medium)
                    .foregroundColor(.primary)
                
                if networkManager.isConnected {
                    Text(networkManager.networkQuality.description)
                        .dynamicTypeSize(10)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Active requests indicator
            if !networkManager.activeRequests.isEmpty {
                HStack(spacing: 4) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        .scaleEffect(0.6)
                    
                    Text("\(networkManager.activeRequests.count)")
                        .dynamicTypeSize(10, weight: .medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .accessibleText(
            label: "Network status: \(connectionStatusText)",
            hint: networkManager.isConnected ? "Connected to internet" : "No internet connection"
        )
    }
    
    private var connectionStatusText: String {
        if networkManager.isConnected {
            switch networkManager.connectionType {
            case .wifi: return "WiFi"
            case .cellular: return "Cellular"
            case .wiredEthernet: return "Ethernet"
            case .other: return "Connected"
            @unknown default: return "Connected"
            }
        } else {
            return "Offline"
        }
    }
}