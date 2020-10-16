//
//  KeyedEncodingContainer+Transform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

extension KeyedEncodingContainer {
    public mutating func encode<T: EncodingTransform>(_ source: T.ValueSource, forKey key: KeyedDecodingContainer<K>.Key, using transform: T) throws {
        let value = try transform.transform(value: source)
        try encode(value, forKey: key)
    }

    public mutating func encodeIfPresent<T: EncodingTransform>(_ source: T.ValueSource?, forKey key: KeyedDecodingContainer<K>.Key, using transform: T) throws {
        guard let source = source else { return }
        let value = try transform.transform(value: source)
        try encode(value, forKey: key)
    }
}
