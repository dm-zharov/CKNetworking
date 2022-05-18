//
//  Encodable+Params.swift
//
//
//  Created by Dmitriy Zharov on 13.08.2021.
//

import Foundation

extension Encodable {
    public func asParams() -> Params {
        let encoder = JSONEncoder()
        
        guard let data = try? encoder.encode(self) else {
            fatalError("Failed to encode data")
        }
        guard let dictionary = try? JSONSerialization.jsonObject(
               with: data,
               options: .allowFragments
        ) as? Params else {
            fatalError("Could not cast JSON content to Params") 
        }
        return dictionary
    }
}
