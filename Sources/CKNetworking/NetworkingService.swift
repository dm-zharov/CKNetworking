import Foundation
import Combine

public protocol NetworkingService {
    var network: NetworkingClient { get }
}

// Синтаксический сахар

public extension NetworkingService {
    // Data
    
    func get(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Data, Error> {
        network.get(route, params: params, data: data)
    }
    
    func post(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Data, Error> {
        network.post(route, params: params, data: data)
    }
    
    func put(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Data, Error> {
        network.put(route, params: params, data: data)
    }
    
    func patch(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Data, Error> {
        network.patch(route, params: params, data: data)
    }
    
    func delete(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Data, Error> {
        network.delete(route, params: params, data: data)
    }
    
    // Void
    
    func get(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Void, Error> {
        network.get(route, params: params, data: data)
    }
    
    func post(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Void, Error> {
        network.post(route, params: params, data: data)
    }
    
    func put(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Void, Error> {
        network.put(route, params: params, data: data)
    }
    
    func patch(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Void, Error> {
        network.patch(route, params: params, data: data)
    }
    
    func delete(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Void, Error> {
        network.delete(route, params: params, data: data)
    }
    
    // JSON
    
    func get(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Any, Error> {
        network.get(route, params: params, data: data)
    }
    
    func post(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Any, Error> {
        network.post(route, params: params, data: data)
    }
    
    func put(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Any, Error> {
        network.put(route, params: params, data: data)
    }
    
    func patch(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Any, Error> {
        network.patch(route, params: params, data: data)
    }
    
    func delete(_ route: String, params: Params = Params(), data: Params = Params()) -> AnyPublisher<Any, Error> {
        network.delete(route, params: params, data: data)
    }
    
    // Decodable
    func get<T: Decodable>(_ route: String,
                           params: Params = Params(),
                           data: Params = Params()) -> AnyPublisher<T, Error> {
        network.get(route, params: params, data: data)
    }
    
    func post<T: Decodable>(_ route: String,
                            params: Params = Params(),
                            data: Params = Params()) -> AnyPublisher<T, Error> {
        network.post(route, params: params, data: data)
    }
    
    func put<T: Decodable>(_ route: String,
                           params: Params = Params(),
                           data: Params = Params()) -> AnyPublisher<T, Error> {
        network.put(route, params: params, data: data)
    }
    
    func patch<T: Decodable>(_ route: String,
                             params: Params = Params(),
                             data: Params = Params(),
                             keypath: String? = nil) -> AnyPublisher<T, Error> {
        network.patch(route, params: params, data: data)
    }
    
    func delete<T: Decodable>(_ route: String,
                              params: Params = Params(),
                              data: Params = Params()) -> AnyPublisher<T, Error> {
        network.delete(route, params: params, data: data)
    }
}
