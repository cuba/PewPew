//
//  KeyedDecodingContainer+Transform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public extension KeyedDecodingContainer {
    func decode<T: DecodingTransform>(using transform: T, forKey key: KeyedDecodingContainer<K>.Key) throws -> T.ValueDestination {
        let json = try self.decode(T.JSONSource.self, forKey: key)
        return try transform.transform(json: json)
    }
    
    func decodeIfPresent<T: DecodingTransform>(using transform: T, forKey key: KeyedDecodingContainer<K>.Key) throws -> T.ValueDestination? {
        guard let json = try self.decodeIfPresent(T.JSONSource.self, forKey: key) else { return nil }
        return try transform.transform(json: json)
    }
}
