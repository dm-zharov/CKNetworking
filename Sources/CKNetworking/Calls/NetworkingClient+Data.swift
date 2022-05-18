//
//  NetworkingClient+Data.swift
//
//
//  Created by Dmitriy Zharov on 18.08.2021.
//

import Foundation
import Combine

public extension NetworkingClient {
    func get(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Data, Error> {
        perform(request(.get, route, params: params, data: data))
    }

    func post(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Data, Error> {
        perform(request(.post, route, params: params, data: data))
    }

    func put(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Data, Error> {
        perform(request(.put, route, params: params, data: data))
    }

    func patch(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Data, Error> {
        perform(request(.patch, route, params: params, data: data))
    }

    func delete(_ route: String, params: Params = Params(), data: Any? = nil) -> AnyPublisher<Data, Error> {
        perform(request(.delete, route, params: params, data: data))
    }
}
