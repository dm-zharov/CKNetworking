//
//  Certificate.swift
//  
//
//  Created by Dmitriy Zharov on 30.08.2021.
//

import Foundation

public enum Certificate {
    public struct Server: Hashable {
        /// Сертификат сервера в формате X509
        public let data: Data
        
        public init(data: Data) {
            self.data = data
        }
    }
    
    public struct Client: Equatable {
        /// Сертификат клиента в формате X509
        public let data: Data
        public let importExportPassphrase: String
        
        public let commonName: String?
        public let emailAddress: String?
        
        public let startDate: Date?
        public let endDate: Date?
        
        public init(data: Data,
                    importExportPassphrase: String,
                    commonName: String? = nil,
                    emailAddress: String? = nil,
                    startDate: Date? = nil,
                    endDate: Date? = nil) {
            self.data = data
            self.importExportPassphrase = importExportPassphrase
            self.commonName = commonName
            self.emailAddress = emailAddress
            self.startDate = startDate
            self.endDate = endDate
        }
    }
    
    case server(Server)
    case client(Client)
}
