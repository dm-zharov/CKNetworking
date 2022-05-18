//
//  NetworkingRequest.swift
//
//
//  Created by Dmitriy Zharov on 18.08.2021.
//

import Foundation
import Combine

public class NetworkingRequest: NSObject {
    /// Query parameters
    public var params = Params()
    /// Body data
    public var data: Any?
    
    var baseURL: URL = URL(string: "localhost")!
    var session: URLSession = URLSession.shared
    
    var headers = [String: String]()

    var parameterEncoding = ParameterEncoding.urlEncoded
    var timeout: TimeInterval?
    var responseValidator: NetworkingResponseValidator?
    
    var route = ""
    var httpVerb = HTTPVerb.get
    
    var multipartData: [MultipartData]?
    
    var storeResponseFilesInCacheDirectory: Bool {
        get { return logger.storeResponseFilesInCacheDirectory }
        set { logger.storeResponseFilesInCacheDirectory = newValue }
    }
    var logLevels: NetworkingLogLevel {
        get { return logger.logLevels }
        set { logger.logLevels = newValue }
    }
    
    private let logger = NetworkingLogger()
    
    let progressPublisher = PassthroughSubject<Progress, Error>()
    
    public func uploadPublisher() -> AnyPublisher<(Data?, Progress), Error> {
        guard let urlRequest = buildURLRequest() else {
            return Fail(
                error: NetworkingError.unableToParseRequest
            ).eraseToAnyPublisher()
        }
        
        logger.log(request: urlRequest)
        
        let callPublisher: AnyPublisher<(Data?, Progress), Error> = session.dataTaskPublisher(for: urlRequest)
            .mapError { error -> NetworkingError in
                return NetworkingError(urlError: error)
            }.tryMap { (data: Data, response: URLResponse) -> Data in
                self.logger.log(response: response, data: data)
                return try self.validate(response: response, data: data)
            }.map { data -> (Data?, Progress) in
                return (data, Progress())
            }.eraseToAnyPublisher()
        
        let progressPublisher: AnyPublisher<(Data?, Progress), Error> = self.progressPublisher
            .map { progress -> (Data?, Progress) in
                return (nil, progress)
            }.eraseToAnyPublisher()
        
        return Publishers.Merge(callPublisher, progressPublisher)
            .receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    public func publisher() -> AnyPublisher<Data, Error> {
        guard let urlRequest = buildURLRequest() else {
            return Fail(
                error: NetworkingError.unableToParseRequest
            ).eraseToAnyPublisher()
        }
        
        logger.log(request: urlRequest)
        
        return session.dataTaskPublisher(for: urlRequest)
            .mapError { error -> NetworkingError in
                return NetworkingError(urlError: error)
            }.tryMap { (data: Data, response: URLResponse) -> Data in
                self.logger.log(response: response, data: data)
                return try self.validate(response: response, data: data)
            }.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    private func urlWithParams() -> URL {
        let url = baseURL.appendingPathComponent(route)
        guard !params.isEmpty else { return url }

        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            var queryItems = urlComponents.queryItems ?? [URLQueryItem]()
            params.forEach { param in
                // arrayParam[] syntax
                if let array = param.value as? [Any] {
                    array.forEach {
                        queryItems.append(URLQueryItem(name: "\(param.key)[]", value: "\($0)"))
                    }
                }
                queryItems.append(URLQueryItem(name: param.key, value: "\(param.value)"))
            }
            urlComponents.queryItems = queryItems
            
            return urlComponents.url ?? url
        }
        
        return url
    }
    
    internal func buildURLRequest() -> URLRequest? {
        let url = urlWithParams()
        var request = URLRequest(url: url)
        
        if httpVerb != .get && multipartData == nil {
            switch parameterEncoding {
            case .urlEncoded:
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            case .json:
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        
        request.httpMethod = httpVerb.rawValue
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let timeout = timeout {
            request.timeoutInterval = timeout
        }
        
        if httpVerb != .get && multipartData == nil {
            switch parameterEncoding {
            case .urlEncoded:
                request.httpBody = percentEncodedString?.data(using: .utf8)

            case .json:
                request.httpBody = jsonData
            }
        }
        
        // Multipart
        if let multiparts = multipartData {
            // Construct a unique boundary to separate values
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = buildMultipartHTTPBody(params: params, multiparts: multiparts, boundary: boundary)
        }
        return request
    }
    
    private func buildMultipartHTTPBody(params: Params, multiparts: [MultipartData], boundary: String) -> Data {
        // Combine all multiparts together
        let allMultiparts: [HTTPBodyConvertible] = [params] + multiparts
        let boundaryEnding = "--\(boundary)--".data(using: .utf8)!
        
        // Convert multiparts to boundary-seperated Data and combine them
        return allMultiparts
            .map { (multipart: HTTPBodyConvertible) -> Data in
                return multipart.buildHTTPBodyPart(boundary: boundary)
            }
            .reduce(Data(), +)
            + boundaryEnding
    }
    
    private var jsonData: Data? {
        guard let data = data else {
            return nil
        }
        return try? JSONSerialization.data(withJSONObject: data)
    }
    
    private var percentEncodedString: String? {
        guard let dictionary = data as? [String: Any] else {
            return nil
        }
        return dictionary.map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            if let array = value as? [Any] {
                return array.map { entry in
                    let escapedValue = "\(entry)"
                        .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
                    return "\(key)[]=\(escapedValue)" 
                }.joined(separator: "&"
                    )
            } else {
                let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
                return "\(escapedKey)=\(escapedValue)"
            }
        }
        .joined(separator: "&")
    }
    
    private func validate(response: URLResponse, data: Data) throws -> Data {
        if let httpURLResponse = response as? HTTPURLResponse {
            guard case .success = httpURLResponse.status?.type else {
                var error = NetworkingError(
                    code: httpURLResponse.statusCode,
                    message: HTTPURLResponse.localizedString(forStatusCode: httpURLResponse.statusCode)
                )
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    error.jsonPayload = json
                }
                throw error
            }
        }
        
        return try responseValidator?.validate(response: response, data: data) ?? data
    }
}

// Thanks to https://stackoverflow.com/questions/26364914/http-request-in-swift-with-post-method
extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

extension NetworkingRequest: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        let progress = Progress(totalUnitCount: totalBytesExpectedToSend)
        progress.completedUnitCount = totalBytesSent
        progressPublisher.send(progress)
    }
}

public enum ParameterEncoding {
    case urlEncoded
    case json
}
