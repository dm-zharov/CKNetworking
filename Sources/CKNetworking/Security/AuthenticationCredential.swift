//
//  AuthenticationCredential.swift
//  
//
//  Created by Dmitriy Zharov on 18.10.2021.
//

import Foundation

/// Аутентификационные данные
public struct AuthenticationCredential: Equatable {
    // Аутентификация на уровне сервера
    public enum Session: Equatable {
        // Отсутствуют
        case serverTrust
        
        // Сертификат пользователя
        case clientCertificate(Certificate.Client)
    }
    
    // Аутентификация на уровне запроса
    public enum Task: Equatable, RawRepresentable {
        case none
        
        case basic(login: String, password: String)
        
        case bearer(token: String)
        
        public var rawValue: String? {
            switch self {
            case .none:
                return nil
                
            case .basic(let login, let password):
                let data =  "\(login):\(password)".data(using: .utf8)!
                let base64String = data.base64EncodedString()
                return "Basic \(base64String)"
                
            case .bearer(let token):
                return "Bearer \(token)"
            }
        }
        
        public init?(rawValue: String?) {
            switch rawValue {
            case let rawValue where rawValue?.contains("Basic") == true:
                guard
                    let base64Value: Substring = rawValue?.split(separator: " ").last,
                    let base64Data: Data = Data(base64Encoded: String(base64Value)),
                    let credentials: [Substring] = String(data: base64Data, encoding: .utf8)?.split(separator: ":")
                else {
                    return nil
                }
                
                guard
                    credentials.count == 2,
                    let loginValue: Substring = credentials.first,
                    let passwordValue: Substring = credentials.last
                else {
                    return nil
                }
                
                self = .basic(login: String(loginValue), password: String(passwordValue))
                
            case let rawValue where rawValue?.contains("Bearer") == true:
                guard let tokenValue: Substring = rawValue?.split(separator: " ").last else {
                    return nil
                }
                
                self = .bearer(token: String(tokenValue))
                
            case nil:
                self = .none
                
            default:
                return nil
            }
        }
    }
    
    public var session: Session
    public var task: Task
    
    public init(session: AuthenticationCredential.Session, task: AuthenticationCredential.Task) {
        self.session = session
        self.task = task
    }
}
