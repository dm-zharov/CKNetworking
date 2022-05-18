//
//  HTTPURLResponse+Status.swift
//
//
//  Created by Dmitriy Zharov on 13.08.2021.
//

import Foundation

public extension HTTPURLResponse {
    var status: NetworkingError.Status? {
        return NetworkingError.Status(rawValue: statusCode)
    }
}
