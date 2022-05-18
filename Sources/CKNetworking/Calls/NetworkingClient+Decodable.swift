//
//  NetworkingClient+Decodable.swift
//
//
//  Created by Dmitriy Zharov on 18.08.2021.
//

import Foundation
import Combine

public extension NetworkingClient {
    func get<T: Decodable>(_ route: String,
                           params: Params = Params(),
                           data: Any? = nil) -> AnyPublisher<T, Error> {
        return get(route, params: params, data: data)
            .tryMap { json -> T in try T.decode(json) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func post<T: Decodable>(_ route: String,
                            params: Params = Params(),
                            data: Any? = nil) -> AnyPublisher<T, Error> {
        return post(route, params: params, data: data)
            .tryMap { json -> T in try T.decode(json) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func put<T: Decodable>(_ route: String,
                           params: Params = Params(),
                           data: Any? = nil) -> AnyPublisher<T, Error> {
        return put(route, params: params as Params)
            .tryMap { json -> T in try T.decode(json) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func patch<T: Decodable>(_ route: String,
                             params: Params = Params(),
                             data: Any? = nil) -> AnyPublisher<T, Error> {
        return patch(route, params: params, data: data)
            .tryMap { json -> T in try T.decode(json) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func delete<T: Decodable>(_ route: String,
                              params: Params = Params(),
                              data: Any? = nil) -> AnyPublisher<T, Error> {
        return delete(route, params: params, data: data)
            .tryMap { json -> T in try T.decode(json) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

public extension Decodable {
    static func decode(_ json: Any) throws -> Self {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        let result = try decoder.decode(Self.self, from: data)
        return result
    }
}
