//
//  NetworkingClient.swift
//
//
//  Created by Dmitriy Zharov on 18.08.2021.
//

import Foundation
import Combine

public class NetworkingClient: NSObject {        
    /// Адрес сервера
    public let baseURL: URL
    /// Политика безопасности в отношении сервера
    public var securityPolicy: SecurityPolicy
    /// Аутентификационные данные
    public var authenticationCredential: AuthenticationCredential
    
    internal var session: URLSession?
    internal let sessionConfiguration: URLSessionConfiguration
    
    /// Хедеры для всех запросов в сессии
    /// Нельзя изменять следующие хедеры сессии: Authorization, Connection, Host, Proxy-Authenticate, Proxy-Authorization, WWW-Authenticate. Используйте `authenticationCredential`
    public var additionalHeaders = [String: String]()
    
    /// Провайдер уникальных хедеров для каждого запроса.
    /// Нельзя изменять следующие хедеры сессии: Authorization, Connection, Host, Proxy-Authenticate, Proxy-Authorization, WWW-Authenticate. Используйте `authenticationCredential`
    public var perRequestHeaders: (() -> [String: String])?
    
    public var parameterEncoding = ParameterEncoding.urlEncoded
    public var timeout: TimeInterval?
    
    /// Валидатор ответов от сервера, требующийся для обработки ошибок от сервера в теле ответа
    public var responseValidator: NetworkingResponseValidator?
    
    /**
        Сохраняет все полученные респонсы в пользовательскую Cache директорию. По умолчанию: false
        Для работы требуется включенное логирование
    */
    public var storeResponseFilesInCacheDirectory: Bool {
        get { return logger.storeResponseFilesInCacheDirectory }
        set { logger.storeResponseFilesInCacheDirectory = newValue }
    }
    /**
        Печатает сетевые запросы в консоль. По умолчанию: .off
    */
    public var logLevels: NetworkingLogLevel {
        get { return logger.logLevels }
        set { logger.logLevels = newValue }
    }
    
    private let logger = NetworkingLogger()

    public init(baseURL: URL,
                securityPolicy: SecurityPolicy = .init(),
                authenticationCredential: AuthenticationCredential = .init(session: .serverTrust, task: .none),
                configuration: URLSessionConfiguration = .default,
                delegate: URLSessionDelegate? = nil,
                timeout: TimeInterval? = nil) {
        self.baseURL = baseURL
        self.securityPolicy = securityPolicy
        self.authenticationCredential = authenticationCredential
        
        self.sessionConfiguration = configuration
        self.timeout = timeout
        
        super.init()
        
        self.session = URLSession(configuration: configuration, delegate: delegate ?? self, delegateQueue: nil)
    }
}

extension NetworkingClient: URLSessionDelegate {
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodServerTrust:
            guard baseURL.host == challenge.protectionSpace.host else {
                // Осуществляем подключение к стороннему серверу? Предоставим проверку доверия системе
                return completionHandler(.performDefaultHandling, nil)
            }
            
            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                // У сервера отсутствует сертификат? Предоставим проверку доверия системе
                return completionHandler(.performDefaultHandling, nil)
            }
            
            if securityPolicy.evaluate(
                serverTrust: challenge.protectionSpace.serverTrust,
                for: challenge.protectionSpace.host
            ) {
                // Серверу можно доверять, осуществляем подключение
                return completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                // Серверу нельзя доверять, отклоняем подключение
                return completionHandler(.cancelAuthenticationChallenge, nil)
            }
        
        case NSURLAuthenticationMethodClientCertificate:
            guard
                case let .clientCertificate(clientCertificate) = authenticationCredential.session,
                let identity = clientCertificate.identity
            else {
                // Отсутствуют аутентификационные данные. Может быть они есть в системе?
                return completionHandler(.performDefaultHandling, nil)
            }
            
            return completionHandler(.useCredential, URLCredential(identity: identity, certificates: nil, persistence: .forSession))
            
        default:
            // Неизвестный тип аутентификации, оставляем на усмотрение системы
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
