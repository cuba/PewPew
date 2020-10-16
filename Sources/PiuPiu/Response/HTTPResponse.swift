//
//  HTTPResponse.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-03-31.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A successful response object. This is retuned when there is any 2xx response.
public struct HTTPResponse<T>: ResponseInterface {
    public let data: T
    public var urlRequest: URLRequest
    public let httpResponse: HTTPURLResponse
    
    public var urlResponse: URLResponse {
        return httpResponse
    }
    
    /// Returns a status code in as an enum
    public var statusCode: StatusCode {
        return StatusCode(rawValue: httpResponse.statusCode)
    }
    
    /// Convenience method for `statusCode.httpError`
    public var httpError: HTTPError? {
        return statusCode.httpError
    }
    
    /// Create a successful response object.
    ///
    /// - Parameters:
    ///   - data: The data object to return.
    ///   - urlRequest: The original `URLRequest` that was created.   
    ///   - httpResponse: The `HTTPURLResponse` that is returned.
    public init(data: T, urlRequest: URLRequest, httpResponse: HTTPURLResponse) {
        self.data = data
        self.urlRequest = urlRequest
        self.httpResponse = httpResponse
    }
}

extension HTTPResponse where T == Data? {
    /// Attempt to Decode the response to a response containing a decodable object
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    public func decodedResponse<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> HTTPResponse<D> {
        let decoded = try self.decode(type, using: decoder)
        return HTTPResponse<D>(data: decoded, urlRequest: urlRequest, httpResponse: httpResponse)
    }
    
    /// Attempt to Decode the response to a response containing a decodable object
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    public func decodedResponseIfPresent<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> HTTPResponse<D?> {
        let decoded = try self.decodeIfPresent(type, using: decoder)
        return HTTPResponse<D?>(data: decoded, urlRequest: urlRequest, httpResponse: httpResponse)
    }
}
