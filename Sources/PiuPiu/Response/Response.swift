//
//  ResponseInterface.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-02-21.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A successful response object. This is retuned when there is any 2xx response.
public struct Response<T>: ResponseInterface {
    public let data: T
    public let urlResponse: URLResponse
    public let urlRequest: URLRequest
    
    /// Create a successful response object.
    ///
    /// - Parameters:
    ///   - data: The data object to return.
    ///   - httpResponse: The `HTTPURLResponse` that is returned.
    ///   - urlRequest: The original `URLRequest` that was created.
    ///   - statusCode: The status code enum that is returned.
    public init(data: T, urlRequest: URLRequest, urlResponse: URLResponse) {
        self.data = data
        self.urlResponse = urlResponse
        self.urlRequest = urlRequest
    }
}

extension Response where T == Data? {
    /// Attempt to Decode the response to a response containing a decodable object
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    public func decodedResponse<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> Response<D> {
        let decoded = try self.decode(type, using: decoder)
        return Response<D>(data: decoded, urlRequest: urlRequest, urlResponse: urlResponse)
    }
    
    /// Attempt to Decode the response to a response containing a decodable object
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    public func decodedResponseIfPresent<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> Response<D?> {
        let decoded = try self.decodeIfPresent(type, using: decoder)
        return Response<D?>(data: decoded, urlRequest: urlRequest, urlResponse: urlResponse)
    }
}
