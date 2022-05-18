//
//  NetworkingClient+JSON.swift
//
//
//  Created by Dmitriy Zharov on 18.08.2021.
//

import Foundation
import Combine

public extension NetworkingClient {
    func get(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Any, Error> {
        get(route, params: params, data: data).toJSON()
    }

    func post(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Any, Error> {
        post(route, params: params, data: data).toJSON()
    }

    func put(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Any, Error> {
        put(route, params: params, data: data).toJSON()
    }

    func patch(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Any, Error> {
        patch(route, params: params, data: data).toJSON()
    }

    func delete(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Any, Error> {
        delete(route, params: params, data: data).toJSON()
    }
}

// Data to JSON
extension Publisher where Output == Data {
    public func toJSON() -> AnyPublisher<Any, Error> {
         tryMap { data -> Any in
             return try JSONSerialization.jsonObject(with: data, options: [])
         }.eraseToAnyPublisher()
    }
}
