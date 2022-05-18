//
//  NetworkingLogger.swift
//
//
//  Created by Dmitriy Zharov on 18.08.2021.
//

import Foundation

class NetworkingLogger {
    var storeResponseFilesInCacheDirectory: Bool = false
    var logLevels = NetworkingLogLevel.off

    func log(request: URLRequest) {
        guard logLevels != .off else {
            return
        }
        
        guard
            let verb = request.httpMethod,
            let url = request.url
        else {
            return
        }
        print("\(verb) '\(url.absoluteString)'")
        
        logHeaders(request.allHTTPHeaderFields)
        if logLevels == .debug {
            logBody(request.httpBody)
        }
    }

    func log(response: URLResponse, data: Data) {
        if storeResponseFilesInCacheDirectory {
            saveResponse(response: response, data: data)
        }
        
        guard logLevels != .off else {
            return
        }
        
        guard
            let response = response as? HTTPURLResponse,
            let url = response.url
        else {
            return
        }
        print("\(response.statusCode) '\(url.absoluteString)'")
        
        logHeaders(response.allHeaderFields)
        if logLevels == .debug {
            logBody(data)
        }
    }
}

// MARK: - Private
extension NetworkingLogger {
    private func logHeaders(_ headers: [AnyHashable : Any]?) {
        guard let headers = headers else { return }
        for (key, value) in headers {
            print("  \(key) : \(value)")
        }
    }

    private func logBody(_ body: Data?) {
        guard var body = body else { return }

        if let json = try? JSONSerialization.jsonObject(with: body, options: []) {
            if let prettyPrintedData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                body = prettyPrintedData
            }
        }
        
        guard let string = String(data: body, encoding: .utf8) else { return }
        print(" HttpBody : \(string)")
    }
}

// MARK: - Response
extension NetworkingLogger {
    private func saveResponse(response: URLResponse, data: Data) {
        guard let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        
        if !FileManager.default.fileExists(atPath: cachesDirectoryURL.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: cachesDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return
            }
        }
        
        guard
            let url = response.url,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return
        }
        
        let relativePath = urlComponents.path.precomposedStringWithCanonicalMapping
        let directoryURL = cachesDirectoryURL.appendingPathComponent(relativePath, isDirectory: true)
        if !FileManager.default.fileExists(atPath: directoryURL.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create cache directory for response")
                return
            }
        }
        
        guard let lastPathComponent = url.pathComponents.last else {
            return
        }
        
        let fileURL = directoryURL.appendingPathComponent(lastPathComponent).appendingPathExtension("json")
        do {
            guard
                let object = try? JSONSerialization.jsonObject(with: data, options: []),
                let prettyPrintedData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
            else {
                print("Failed to create pretty printed JSON from response")
                return
            }
            try prettyPrintedData.write(to: fileURL)
            print("Did write response to \(fileURL)")
        } catch {
            print("Failed to write response to cache directory")
            return
        }
    }
}
