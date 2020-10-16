//
//  ResponseInterface+Extensions.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-02-21.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

extension Response where T == Data? {
    /// Create a mock response object.
    ///
    /// - Parameters:
    ///   - urlRequest: The urlRequest to use on the response
    ///   - encodable: The object to encode into JSON
    ///   - statusCode: The statusCode to use on the response
    ///   - headers: The headers to use on the response
    ///   - encoder: The encoder to use to encode the object
    /// - Returns: A response object with a Data? data type
    /// - Throws: Throws RequestError.missingUrl if a url cannot be taken from the urlRequest
    public static func makeMockJSONResponse<T: Encodable>(with urlRequest: URLRequest, encodable: T, statusCode: StatusCode, headers: [String: String] = [:], encoder: JSONEncoder = JSONEncoder()) throws -> Response<Data?> {
        let data = try JSONEncoder().encode(encodable)
        return try makeMockResponse(with: urlRequest, data: data, statusCode: statusCode, headers: headers)
    }
    
    /// Create a mock response object.
    ///
    /// - Parameters:
    ///   - urlRequest: The urlRequest to use on the response
    ///   - jsonObject: The json object to encode
    ///   - options: The options that will be used for serialization
    ///   - statusCode: The statusCode to use on the response
    ///   - headers: The headers to use on the response
    /// - Returns: A response object with a Data? data type
    /// - Throws: Throws RequestError.missingUrl if a url cannot be taken from the urlRequest
    public static func makeMockResponse(with urlRequest: URLRequest, jsonObject: [String: Any?], options: JSONSerialization.WritingOptions = [], statusCode: StatusCode, headers: [String: String] = [:]) throws -> Response<Data?> {
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
        return try makeMockResponse(with: urlRequest, data: data, statusCode: statusCode, headers: headers)
    }
    
    /// Create a mock response object.
    ///
    /// - Parameters:
    ///   - urlRequest: The urlRequest to use on the response
    ///   - jsonString: The string to encode
    ///   - encoding: The string encoding that will be used
    ///   - statusCode: The statusCode to use on the response
    ///   - headers: The headers to use on the response
    /// - Returns: A response object with a Data? data type
    /// - Throws: Throws RequestError.missingUrl if a url cannot be taken from the urlRequest
    public static func makeMockResponse(with urlRequest: URLRequest, jsonString: String, encoding: String.Encoding = .utf8, statusCode: StatusCode, headers: [String: String] = [:]) throws -> Response<Data?> {
        let data = jsonString.data(using: encoding)
        return try makeMockResponse(with: urlRequest, data: data, statusCode: statusCode, headers: headers)
    }
    
    /// Create a mock response object.
    ///
    /// - Parameters:
    ///   - urlRequest: The urlRequest to use on the response
    ///   - data: The data to use on the response
    ///   - statusCode: The statusCode to use on the response
    ///   - headers: The headers to use on the response
    /// - Returns: A response object with a Data? data type
    /// - Throws: Throws RequestError.missingUrl if a url cannot be taken from the urlRequest
    public static func makeMockResponse(with urlRequest: URLRequest, data: Data? = nil, statusCode: StatusCode, headers: [String: String] = [:]) throws -> Response<Data?> {
        let url = urlRequest.url!
        let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode.rawValue, httpVersion: nil, headerFields: headers)!
        let response = Response(data: data, urlRequest: urlRequest, urlResponse: httpResponse)
        
        return response
    }
}
