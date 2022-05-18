//
//  NetworkingClient+Requests.swift
//
//
//  Created by Dmitriy Zharov on 18.08.2021.
//

import Foundation
import Combine

public extension NetworkingClient {
    internal func request(_ httpVerb: HTTPVerb,
                          _ route: String,
                          params: Params = Params(),
                          data: Any? = nil) -> NetworkingRequest {
        let req = NetworkingRequest()
        req.baseURL = baseURL
        req.storeResponseFilesInCacheDirectory = storeResponseFilesInCacheDirectory
        req.logLevels = logLevels
        req.headers = additionalHeaders.merging(
            (perRequestHeaders?() ?? [:]),
            uniquingKeysWith: { _, perRequestHeader in
                return perRequestHeader
            }
        )
        req.set(credential: authenticationCredential.task)
        req.httpVerb = httpVerb
        req.route = route
        req.params = params
        req.data = data
        req.parameterEncoding = parameterEncoding
        req.timeout = timeout
        req.responseValidator = responseValidator
        req.session = session ?? URLSession.shared
        
        return req
    }
    
    internal func perform(_ request: NetworkingRequest) -> AnyPublisher<Data, Error> {
        // Проверяет, изменились ли авторизационные данные, после получения ошибки авторизации.
        // Если изменились, то обновляет авторизационный хедер запроса и повторяет его.
        let originalCredential = authenticationCredential
        return request.publisher()
            .tryCatch { [weak self] error -> AnyPublisher<Data, Error> in
                // В стандартном процессе, ошибка авторизации будет обработана через didReceiveChallenge для task.
                // Однако если были предоставлены данные, которые не могут быть обработаны NSURLSession (к примеру, она может в Basic либо Digest, но не может в Bearer),
                // то мы самостоятельно обновляем авторизационные данные и повторяем запрос.
                guard
                    let self = self,
                    let error = error as? NetworkingError,
                    error.status == .unauthorized
                else {
                    throw error
                }
                
                let currentCredential = self.authenticationCredential
                guard originalCredential != currentCredential else {
                    throw error
                }
                
                request.set(credential: currentCredential.task)
                
                return request.publisher()
            }.eraseToAnyPublisher()
    }
}

// MARK: - Extensions
private extension NetworkingRequest {
    func set(credential: AuthenticationCredential.Task) {
        headers["Authorization"] = credential.rawValue
    }
}
