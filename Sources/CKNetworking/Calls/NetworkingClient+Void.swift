//
//  NetworkingClient+Void.swift
//
//
//  Created by Dmitriy Zharov on 18.08.2021.
//

import Foundation
import Combine

public extension NetworkingClient {
    func get(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Void, Error> {
        get(route, params: params, data: data)
            .map { (_: Data) -> Void in () }
            .eraseToAnyPublisher()
    }

    func post(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Void, Error> {
        post(route, params: params, data: data)
            .map { (_: Data) -> Void in () }
        .eraseToAnyPublisher()
    }

    func put(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Void, Error> {
        put(route, params: params, data: data)
            .map { (_: Data) -> Void in () }
            .eraseToAnyPublisher()
    }
    
    func patch(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Void, Error> {
        patch(route, params: params, data: data)
            .map { (_: Data) -> Void in () }
            .eraseToAnyPublisher()
    }

    func delete(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Void, Error> {
        delete(route, params: params, data: data)
            .map { (_: Data) -> Void in () }
            .eraseToAnyPublisher()
    }
}
