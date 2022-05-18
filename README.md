# CKNetworking

URLSession + Combine. Подробная документация в процессе написания...

## Возможности
– Простая реализация SSLPinning
- Авторизация по пользовательскому сертификату
- Авторизация с использованием `Bearer`-токена (нативно доступны лишь `Basic` и `Digest`)
- Логирование в консоль сетевой активности
- Возможность сформировать директорию с файловым кешем из ответов от сервера. На базе кеша можно, к примеру, реализовать мок-сервер.
- Кастомная обработка ответов от сервера. Пример: популярная ситуация, когда респонс всегда `200`, а теле ответа лежит словарь:
```
[ "code": 500, "status": false, "message: "Произошла ошибка" ]
```

## Пример настоящей логики, написанной на базе CKNetworking

### Инициализация сетевого сервиса

Реальный сервер:
```
APIService(configuration: .remote(.psi), useSSLPinning: false)
```

Локальный (мок) сервер:
```
APIService(configuration: .local)
```

### Реализация сетевого сервиса

Следующий пример реализует данные сценарии:
- При подключении к серверу передается пользовательский сертификат.
- У пользователя отсутствует токен (`Bearer`), либо он истек. При отправке запроса из любого места приложения от сервера поступает
ошибка `Unauthorized (401)`, которая обрабатывается следующим образом: происходит получение/обновление токена и повторная отправка неуспешного запроса.
- Включение/отключение SSL Pinning.


```
public class APIService: NSObject {
    public enum Configuration {
        public struct Endpoint: RawRepresentable, Equatable, Hashable {
            public let rawValue: URL

            public init(rawValue: URL) {
                self.rawValue = rawValue
            }

            public static let ift = Endpoint(rawValue: URL(string: "https://.../api/v0")!)
            public static let psi = Endpoint(rawValue: URL(string: "https://.../api/v0")!)
        }
        
        public enum Credential {
            case login(String, password: String)
            case certificate(Certificate.Client)
            case none
            
            public init(endpoint: Endpoint) {
                switch endpoint {
                case .ift:
                    self = .login("17559962", password: "test") // Пользователь по умолчанию

                case .psi:
                    self = .login("16710489", password: "test") // Пользователь по умолчанию

                default:
                    self = .none
                }
            }
        }
        
        case remote(Endpoint, credential: Credential = .none)
        case local
    }
    
    public var network = NetworkingClient(baseURL: URL(string: "localhost")!)
    
    public var configuration: Configuration {
        didSet {
            updateConfiguration()
        }
    }
    public var useSSLPinning: Bool {
        didSet {
            updateConfiguration()
        }
    }
    
    private var authenticationCancellable: AnyCancellable?
    
    public init(configuration: Configuration, useSSLPinning: Bool = true) {
        self.configuration = configuration
        self.useSSLPinning = useSSLPinning
        super.init()
        updateConfiguration()
    }
}

// MARK: - Configuration
extension APIService {
    /// Произвести обновление конфигурации соеденния в соответствии с текущими настройками
    public func updateConfiguration() {
        let url: URL
        let securityPolicy: SecurityPolicy
        let authenticationCredential: AuthenticationCredential
        let sessionConfiguration: URLSessionConfiguration
        
        switch configuration {
        case .local:
            url = Bundle.module.url(forResource: "DemoHost", withExtension: "bundle")!
            securityPolicy = .defaultPolicy
            authenticationCredential = .init(session: .serverTrust, task: .none)
            sessionConfiguration = .ephemeral
            sessionConfiguration.protocolClasses = [DemoURLProtocol.self]
            
        case .remote(let endpoint, let credential):
            url = endpoint.rawValue
            
            if useSSLPinning {
                securityPolicy = .policy(with: .certificate)
            } else {
                securityPolicy = {
                    var securityPolicy = SecurityPolicy.defaultPolicy
                    securityPolicy.allowInvalidCertificates = true
                    securityPolicy.validatesDomainName = false
                    
                    return securityPolicy
                }()
            }
            
            switch credential {
            case .login:
                authenticationCredential = .init(
                    session: .serverTrust,
                    task: .none
                )
                
            case .certificate(let clientCertificate):
                authenticationCredential = .init(
                    session: .clientCertificate(clientCertificate),
                    task: .none
                )

            case .none:
                authenticationCredential = .init(session: .serverTrust, task: .none)
            }
            
            sessionConfiguration = .`default`
        }
        
        let client = NetworkingClient(
            baseURL: url,
            securityPolicy: securityPolicy,
            authenticationCredential: authenticationCredential,
            configuration: sessionConfiguration,
            delegate: self
        )
        
        client.parameterEncoding = .json
        client.timeout = 15
        
        client.storeResponseFilesInCacheDirectory = false // MARK: Для формирования локальных JSON-респонсов выставьте данный флаг в true
        client.logLevels = .debug
        
        client.perRequestHeaders = self.perRequestHeaders
        client.responseValidator = self
        
        self.network = client
    }
}

extension APIService: APIServiceProtocol {
    public func validate(response: URLResponse, data: Data) throws -> Data {
        guard let httpURLResponse = response as? HTTPURLResponse else {
            return data
        }
        
        // MARK: Вложенная в `фейковый` ответ от сервера великая троица
        guard
            let status = httpURLResponse.value(forHTTPHeaderField: "success"),
            let code = httpURLResponse.value(forHTTPHeaderField: "status"),
            let message = httpURLResponse.value(forHTTPHeaderField: "message")
        else {
            return data
        }
        
        switch status {
        case "false":
            throw NetworkingError(
                code: Int(code) ?? -1,
                message: message
            )

        default:
            return data
        }
    }
}

// MARK: - Private
extension APIService {
    private func perRequestHeaders() -> [String: String] {
        ["TransactionId": UUID().uuidString]
    }
}

// MARK: - URLSessionTaskDelegate
extension APIService: URLSessionTaskDelegate {
    // При подключении к серверу у пользователя запрашивается сертификат.
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodServerTrust:
            guard network.baseURL.host == challenge.protectionSpace.host else {
                // Осуществляем подключение к стороннему серверу? Предоставим проверку доверия системе
                return completionHandler(.performDefaultHandling, nil)
            }

            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                // У сервера отсутствует сертификат? Предоставим проверку доверия системе
                return completionHandler(.performDefaultHandling, nil)
            }

            if network.securityPolicy.evaluate(
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
                case let .clientCertificate(clientCertificate) = network.authenticationCredential.session,
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
    
    // У пользователя отсутствует токен (`Bearer`), либо он истек. При отправке запроса из любого места приложения от сервера поступает
    // ошибка `Unauthorized (401)`, которая обрабатывается следующим образом: происходит получение/обновление токена и повторная отправка неуспешного запроса.
    приходит ошибка `Unauthorized 401`, которая обрабатывается в данном методе.
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.previousFailureCount == 0 else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        switch network.authenticationCredential.task {
        case .bearer:
            fallthrough // TODO: Изменить, когда будет использоваться рефреш токен
        case .none:
            guard
                case let .remote(_, credential) = configuration,
                case let .login(login, password) = credential
            else {
                return
            }
            
            authenticationCancellable = getUserToken(login: login, password: password)
                .sink(
                    receiveCompletion: { _ in
                        // Задача, при выполнении которой пришел 401, все же завершится с ошибкой.
                        // Однако автоматически будет отправлен новый запрос с измененными хедерами (данная логика заложена в CKNetworking.NetworkingClient)
                        completionHandler(.performDefaultHandling, nil)
                    },
                    receiveValue: { [weak self] token in
                        // Передаем в CKNetworking.NetworkingClient авторизационные данные.
                        self?.network.authenticationCredential.task = .bearer(token: token.accessToken)
                    })
            
        default:
            // Неизвестный тип аутентификации, оставляем обработку ошибки на усмотрение системы
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

```

### Реализация интерфейса для серверного API

```
extension API {
    public func getDocumentsList(limit: Int = 20,
                                 page: Int = 1,
                                 parameters: DocumentSearchParams) -> AnyPublisher<FoundDocumentsListPage, Error> {
        post(
            "/documents/list",
            params: [
                "limit": limit,
                "page": page
            ], // Можно вручную сформировать словарь
            data: parameters.asParams() // Можно передать объект как словарь
        )
    }
```
