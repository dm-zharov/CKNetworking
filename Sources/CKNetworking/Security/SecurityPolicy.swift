//
//  SecurityPolicy.swift
//  
//
//  Created by Dmitriy Zharov on 18.10.2021.
//

import Foundation

public struct SecurityPolicy {
    /// Критерий, по которому определяется доверие к сертификату сервера
    public let pinningMode: SSLPinningMode
    /// Сертификаты для пиннинга
    public let pinnedCertificates: Set<Certificate.Server>
    /// Публичные ключи сертификатов для пиннинга
    public let pinnedPublicKeys: Array<SecKey>
    
    /// Доверять ли серверу с неправильным или истекшим SSL  сертификатом. По умолчанию: `false`.
    public var allowInvalidCertificates = false
    /// Сверять ли поле CN сертификата сервера с запиннеными сертификатами. По умолчанию: `true`.
    public var validatesDomainName = true
    
    public init(pinningMode: SSLPinningMode = .`none`, pinnedCertificates: Set<Certificate.Server> = []) {
        self.pinningMode = pinningMode
        self.pinnedCertificates = pinnedCertificates
        self.pinnedPublicKeys = pinnedCertificates.map { serverCertificate in
            guard let publicKey = serverCertificate.publicKey else {
                fatalError()
            }
            return publicKey
        }
    }
}

// MARK: - Проверка достоверности сертификата сервера
public extension SecurityPolicy {
    /// Проверка достоверности сертификата сервера
    /// - Parameters:
    ///   - serverTrust: Сертификат сервера в формате X.509
    ///   - domain: Домен сервера. Если будет передан nil, домен не будет валидирован.
    /// - Returns: Можно ли доверять серверу серверу?
    func evaluate(serverTrust: SecTrust?, for domain: String?) -> Bool {
        //  Из Apple Docs:
        // https://developer.apple.com/library/mac/documentation/NetworkingInternet/Conceptual/NetworkingTopics/Articles/OverridingSSLChainValidationCorrectly.html
        //
        //  "Do not implicitly trust self-signed certificates as anchors (kSecTrustOptionImplicitAnchors).
        //  Instead, add your own (self-signed) CA certificate to the list of trusted anchors."
        
        guard
            let serverTrust = serverTrust,
            let domain = domain
        else {
            return false
        }
        
        if allowInvalidCertificates && validatesDomainName && (pinningMode == .none || pinnedCertificates.isEmpty) {
            print("Для валидации доменного имени в самоподписанном сертификате вы обязаны настроить SSL пиннинг.")
            return false
        }
        
        let policies: [SecPolicy]
        if validatesDomainName {
            policies = [SecPolicyCreateSSL(true, domain as CFString)]
        } else {
            policies = [SecPolicyCreateBasicX509()]
        }
        
        SecTrustSetPolicies(serverTrust, policies as CFArray)
        
        if pinningMode == .none {
            return allowInvalidCertificates || isValid(serverTrust: serverTrust)
        } else if !allowInvalidCertificates && !isValid(serverTrust: serverTrust) {
            return false
        }
        
        switch pinningMode {
        case .certificate:
            SecTrustSetAnchorCertificates(
                serverTrust,
                pinnedCertificates.map { serverCertificate -> SecCertificate in
                    guard let secCertificate = SecCertificateCreateWithData(nil, serverCertificate.data as CFData) else {
                        fatalError()
                    }
                    return secCertificate
                } as CFArray
            )
            
            guard isValid(serverTrust: serverTrust) else {
                return false
            }
            
            // Получаем цепь сертификатов после валидации, которая должна завершаться запиненным сертификатом
            return certificateChain(for: serverTrust).reversed().contains { serverCertificate in
                pinnedCertificates.contains(serverCertificate)
            }
            
        case .publicKey:
            var trustedPublicKeyCount = 0
            certificateChain(for: serverTrust).forEach { serverCertificate in
                guard let publicKey = serverCertificate.publicKey else {
                    fatalError()
                }
                for pinnedPublicKey in pinnedPublicKeys {
                    if publicKey == pinnedPublicKey {
                        trustedPublicKeyCount += 1
                    }
                }
            }
            return trustedPublicKeyCount > 0
        default:
            return false
        }
    }
    
    private func isValid(serverTrust: SecTrust) -> Bool {
        var error: CFError?
        let result = SecTrustEvaluateWithError(serverTrust, &error)
        if let error = error {
            print(error)
        }        
        return result
    }
    
    private func certificateChain(for serverTrust: SecTrust) -> Array<Certificate.Server> {
        if #available(iOS 15.0, *) {
            guard let secCertificates = SecTrustCopyCertificateChain(serverTrust) as? Array<SecCertificate> else {
                fatalError()
            }
            return secCertificates.map { secCertificate in
                Certificate.Server(
                    data: SecCertificateCopyData(secCertificate) as Data
                )
            }
        } else {
            var serverCertificates: [Certificate.Server] = []
            for index in 0...SecTrustGetCertificateCount(serverTrust) {
                guard let secCertificate = SecTrustGetCertificateAtIndex(serverTrust, index) else {
                    fatalError()
                }
                let serverCertificate = Certificate.Server(
                    data: SecCertificateCopyData(secCertificate) as Data
                )
                serverCertificates.append(serverCertificate)
            }
            return serverCertificates
        }
    }
}

// MARK: - Преднастроенные политики
public extension SecurityPolicy {
    /// Стандартная политика безопасности, не разрешающая невалидные сертификаты, сверяющая доменное имя и не осуществляющая пиннинг сертификатов либо публичных ключей
    static var defaultPolicy: Self {
        .init(pinningMode: .none, pinnedCertificates: [])
    }
    
    /// Политика безопасности с указанным способом пиннинга
    /// Сертификаты для пиннинга будут автоматически найдены в главном бандле приложения по расширению `cer`
    ///
    /// - Parameter pinningMode: Способ пиннинга сертификата
    /// - Returns: Настроенная политика
    static func policy(with pinningMode: SSLPinningMode) -> Self {
        let pinnedCertificates = certificates(in: Bundle.main)
        return .init(pinningMode: pinningMode, pinnedCertificates: pinnedCertificates)
    }
    
    /// Политика безопасности с указанным способом пиннинга
    /// - Parameters:
    ///   - pinningMode: Способ пиннинга сертификата
    ///   - pinnedCertificates: Список сертификатов для пиннинга
    /// - Returns: Настроенная политика
    static func policy(with pinningMode: SSLPinningMode, pinnedCertificates: Set<Certificate.Server>) -> Self {
        .init(pinningMode: pinningMode, pinnedCertificates: pinnedCertificates)
    }
}

// MARK: - Поиск сертификатов
public extension SecurityPolicy {
    static func certificates(in bundle: Bundle) -> Set<Certificate.Server> {
        guard let urls = bundle.urls(forResourcesWithExtension: "cer", subdirectory: nil) else {
            return []
        }
        let certificates: [Certificate.Server] = urls.compactMap { url in
            guard let data = try? Data(contentsOf: url) else {
                return nil
            }
            return .init(data: data)
        }
        return Set(certificates)
    }
}
