//
//  Transform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// Defines a protocol for encoding data to JSON
public protocol EncodingTransform {
    associatedtype ValueSource
    associatedtype JSONDestination: Encodable
    
    /// Transform any type to an `Encodable` type which will be encoded further by the `Encoder`.
    func transform(value: Self.ValueSource) throws -> Self.JSONDestination
}

/// Defines a protocol for decoding data from JSON
public protocol DecodingTransform {
    associatedtype JSONSource: Decodable
    associatedtype ValueDestination
    
    /// Transform a `Decodable` value to any type. The `Decodable` type specified will be parsed by a `Decoder`.
    func transform(json: Self.JSONSource) throws -> Self.ValueDestination
}

/// A protocol that encompasses both `EncodingTransform` and `DecodingTransform`
public protocol Transform: EncodingTransform, DecodingTransform {}
