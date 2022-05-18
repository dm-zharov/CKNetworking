//
//  NetworkingResponseValidator.swift
//  
//
//  Created by Dmitriy Zharov on 24.08.2021.
//

import Foundation

public protocol NetworkingResponseValidator {
    /// Метод, который обрабатывает ответ от сервера и либо генерирует соответствующую ошибку, либо возвращает данные
    func validate(response: URLResponse, data: Data) throws -> Data
}
