//
//  ResponseInterface.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-15.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The protocol wrapping the response object.
public protocol ResponseInterface {
    associatedtype T
    
    var data: T { get }
    var urlResponse: URLResponse { get }
    var urlRequest: URLRequest { get }
}

extension ResponseInterface where T == Data? {
    public func makeHTTPResponse() throws -> HTTPResponse<T> {
        // Ensure there is a http response
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw ResponseError.notHTTPResponse
        }
        
        return HTTPResponse(data: data, urlRequest: urlRequest, httpResponse: httpResponse)
    }
    
    /// Attempt to unwrap the response data.
    ///
    /// - Returns: The unwrapped object
    /// - Throws: `SerializationError`
    public func unwrapData() throws -> Data {
        // Check if we have the data we need
        guard let unwrappedData = data else {
            throw ResponseError.unexpectedEmptyResponse
        }
        
        return unwrappedData
    }
    
    /// Attempt to deserialize the response data into a JSON string.
    ///
    /// - Parameter encoding: The string encoding type. The dafault is `.utf8`.
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    public func decodeString(encoding: String.Encoding = .utf8) throws -> String {
        let data = try unwrapData()
        
        // Attempt to deserialize the object.
        guard let string = String(data: data, encoding: encoding) else {
            throw ResponseError.failedToDecodeDataToString(encoding: encoding)
        }
        
        return string
    }
    
    /// Attempt to decode a JSON object (`Any`) from the response data.
    ///
    /// - Parameter options: Reading options. Default is set to `.mutableContainers`.
    /// - Returns: JSON object as `Any`
    /// - Throws: `SerializationError`
    public func decodeJSONObject(options: JSONSerialization.ReadingOptions = .mutableContainers) throws -> Any {
        let data = try self.unwrapData()
        return try JSONSerialization.jsonObject(with: data, options: options)
    }
    
    /// Attempt to Decode the response data into a Decodable object.
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - dateDecodingStrategy: The default date encoding strategy to use. The default is `.rfc3339` (`yyyy-MM-dd'T'HH:mm:ssZZZZZ`)
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    public func decode<D: Decodable>(_ type: D.Type, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy) throws  -> D {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return try decode(type, using: decoder)
    }
    
    /// Attempt to Decode the response data into a Decodable object.
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    public func decode<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws  -> D {
        let data = try self.unwrapData()
        return try decoder.decode(type, from: data)
    }
    
    /// Attempt to Decode the response data into a Decodable object.
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    public func decodeIfPresent<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws  -> D? {
        guard let data = self.data else { return nil }
        return try decoder.decode(type, from: data)
    }
    
    /// A method to print the request and response in the console.
    /// **Warning** This should not be used in a production environment.
    public func debug() {
        print("===========================================")
        print(makeRequestMarkdown())
        print("-------------------------------------------")
        print(makeResponseMarkdown())
        print("===========================================")
    }
    
    /// A method to print the request in the console.
    /// **Warning** This should not be used in a production environment.
    public func makeRequestMarkdown() -> String {
        var components: [String] = [
            "## REQUEST",
            "[\(urlRequest.httpMethod!)] \(urlRequest.url!)"
        ]
        
        if let headerFields = urlRequest.allHTTPHeaderFields {
            components.append("### Headers")
            
            for (key, value) in headerFields {
                components.append("* \(key): \(value)")
            }
        }
        
        if let body = urlRequest.httpBody {
            components.append("### Body")
            components.append("```json")
            
            if let json = String(data: body, encoding: .utf8) {
                components.append(json)
            } else {
                components.append(body.base64EncodedString())
            }
            
            components.append("```")
        }
        
        return components.joined(separator: "\n")
    }
    
    /// A method to print the response in the console.
    /// **Warning** This should not be used in a production environment.
    public func makeResponseMarkdown() -> String {
        var components: [String] = ["## RESPONSE"]
        
        if let httpResponse = self.urlResponse as? HTTPURLResponse {
            components.append("[\(urlRequest.httpMethod!)] (\(httpResponse.statusCode)) \(urlRequest.url!)")
            
            components.append("### Headers")
            for (key, value) in httpResponse.allHeaderFields {
                components.append("* \(key): \(value)")
            }
        } else {
            components.append("[\(urlRequest.httpMethod!)] \(urlRequest.url!)")
        }
        
        if data != nil {
            components.append("### Body")
            components.append("```json")
            do {
                let json = try decodeString(encoding: .utf8)
                components.append(json)
            } catch {
                components.append("\(error)")
            }
            components.append("```")
        }
        
        return components.joined(separator: "\n")
    }
}
