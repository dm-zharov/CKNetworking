// swiftlint:disable:this file_name

//
//  Certificate+Security.swift
//
//
//  Created by Dmitriy Zharov on 31.08.2021.
//

import Foundation
import Security

public extension Certificate.Server {
    var publicKey: SecKey? {
        guard let secCertificate = SecCertificateCreateWithData(nil, data as CFData) else {
            return nil
        }
        
        var serverTrust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        SecTrustCreateWithCertificates(secCertificate, policy, &serverTrust)
        
        guard let serverTrust = serverTrust else {
            return nil
        }
        
        _ = SecTrustEvaluateWithError(serverTrust, nil)
        
        if #available(iOS 14.0, *) {
            return SecTrustCopyKey(serverTrust)
        } else {
            return SecTrustCopyPublicKey(serverTrust)
        }
    }
}

public extension Certificate.Client {
    var identity: SecIdentity? {
        var items: CFArray?
        
        let status = SecPKCS12Import(
            data as NSData,
            [kSecImportExportPassphrase as String: importExportPassphrase] as NSDictionary,
            &items
        )
        
        guard status == noErr else {
            return nil
        }
        
        guard
            let identityDictionariesArray = items as? [[String: Any]],
            let identityDictionary = identityDictionariesArray.first
        else {
            return nil
        }
        
        guard let identity = identityDictionary[kSecImportItemIdentity as String] else {
            return nil
        }
        
        return .some(identity as! SecIdentity)
    }
    
    var certificate: SecCertificate? {
        guard let identity = identity else {
            return nil
        }
        
        var certificate: SecCertificate?
        SecIdentityCopyCertificate(identity, &certificate)
        return certificate
    }
}
// swiftlint:enable file_name
