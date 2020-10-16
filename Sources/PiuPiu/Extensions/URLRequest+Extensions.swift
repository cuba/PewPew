//
//  URLRequest+Extensions.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-06.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

// MARK: - Encoding

extension URLRequest {
    public init(url: URL, method: HTTPMethod) {
        self.init(url: url)
        self.httpMethod = method.rawValue
    }
    
    /// Add JSON body to the request from an `Encodable` object using the `JSONEncoder`.
    ///
    /// - Parameters:
    ///   - encodable: The `Encodable` object to serialize into JSON using the `JSONEncoder`.
    ///   - encoder: The encoder to use for encoding the encodable object. Default is a the system encoder.
    /// - Throws: Any serialization errors thrown by the `JSONEncoder`.
    public mutating func setJSONBody<T: Encodable>(encodable: T, encoder: JSONEncoder = JSONEncoder()) throws {
        self.httpBody = try encoder.encode(encodable)
        ensureJSONContentType()
    }
    
    /// Add body to the request from a string.
    ///
    /// - Parameters:
    ///   - string: The string to add to the body.
    ///   - encoding: The encoding type to use when adding the string.
    public mutating func setHTTPBody(string: String, encoding: String.Encoding = .utf8) {
        self.httpBody = string.data(using: encoding)
    }
    
    /// Add JSON body to the request from a string. Adds the content type header.
    ///
    /// - Parameters:
    ///   - string: The string to add to the body.
    ///   - encoding: The encoding type to use when adding the string.
    public mutating func setJSONBody(string: String, encoding: String.Encoding = .utf8) {
        self.setHTTPBody(string: string, encoding: encoding)
        ensureJSONContentType()
    }
    
    
    /// Add JSON body to the request from a JSON Object.
    ///
    /// - Parameters:
    ///   - jsonObject: The JSON Object to encode into the request body using `JSONSerialization`.
    ///   - options: The writing options to use when encoding.
    /// - Throws: Any errors thrown by `JSONSerialization`.
    public mutating func setHTTPBody(jsonObject: [String: Any?], options: JSONSerialization.WritingOptions = []) throws {
        self.httpBody = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
    }
    
    /// Add HTTP body to the request from a JSON Object.
    ///
    /// - Parameters:
    ///   - jsonObject: The JSON Object to encode into the request body using `JSONSerialization`. This does the same thing as the `setHTTPBody(jsonArray:options:)` method except that it also adds to `Content-Type` header.
    ///   - options: The writing options to use when encoding.
    /// - Throws: Any errors thrown by `JSONSerialization`.
    public mutating func setJSONBody(jsonObject: [String: Any?], options: JSONSerialization.WritingOptions = []) throws {
        try setHTTPBody(jsonObject: jsonObject, options: options)
        ensureJSONContentType()
    }
    
    /// Add HTTP body to the request from a JSON Array.
    ///
    /// - Parameters:
    ///   - jsonArray: The JSON Object array to encode into the request body using `JSONSerialization`.
    ///   - options: The writing options to use when encoding.
    /// - Throws: Any errors thrown by `JSONSerialization`.
    public mutating func setHTTPBody(jsonArray: [[String: Any?]], options: JSONSerialization.WritingOptions = []) throws {
        self.httpBody = try JSONSerialization.data(withJSONObject: jsonArray, options: options)
    }
    
    /// Add JSON body to the request from a JSON Array. This does the same thing as the `setHTTPBody(jsonArray:options:)` method except that it also adds to `Content-Type` header.
    ///
    /// - Parameters:
    ///   - jsonArray: The JSON Object array to encode into the request body using `JSONSerialization`.
    ///   - options: The writing options to use when encoding.
    /// - Throws: Any errors thrown by `JSONSerialization`.
    public mutating func setJSONBody(jsonArray: [[String: Any?]], options: JSONSerialization.WritingOptions = []) throws {
        try setHTTPBody(jsonArray: jsonArray, options: options)
        ensureJSONContentType()
    }
    
    /// Add JSON body to the request from an `Encodable` object using the `JSONEncoder`.
    ///
    /// - Parameters:
    ///   - encodable: The `Encodable` object to serialize into JSON using the `JSONEncoder`.
    /// - Throws: Any serialization errors thrown by the `JSONEncoder`.
    public mutating func setJSONBody<T: Encodable>(_ encodable: T, encoder: JSONEncoder = JSONEncoder()) throws {
        try setJSONBody(encodable: encodable, encoder: encoder)
    }
    
    public mutating func ensureJSONContentType() {
        if self.value(forHTTPHeaderField: "Content-Type") == nil {
            self.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }
}

// MARK: - Testing Extensions

extension URLRequest {
    /// Returns values extracted from the path. The path must match exactly.
    ///
    /// - Parameter pattern: The pattern to match which must be exactly the same.
    /// - Returns: The matched path values. Any incosistency will return nil. The size of the array will always be the number of wildcards passed.
    public func pathValues(matching pattern: [PathComponent]) -> [PathValue]? {
        return url?.pathValues(matching: pattern)
    }
    
    /// Returns an string value from the extracted path values (`PathValue`) at the given index.
    ///
    /// - Parameters:
    ///   - index: The index of the extracted value. Needs to be within the bounds of the pattern or the application will crash.
    ///   - pattern: The pattern used to extract the values
    /// - Returns: An integer value if found in the exact position of the extracted pattern.
    public func integerValue(atIndex index: Int, matching pattern: [PathComponent]) -> Int? {
        return url?.integerValue(atIndex: index, matching: pattern)
    }
    
    /// Returns an string value from the extracted path values (`PathValue`) at the given index.
    ///
    /// - Parameters:
    ///   - index: The index of the extracted value. Needs to be within the bounds of the pattern or the application will crash.
    ///   - pattern: The pattern used to extract the values
    /// - Returns: An integer value if found in the exact position of the extracted pattern.
    public func stringValue(atIndex index: Int, matching pattern: [PathComponent]) -> String? {
        return url?.stringValue(atIndex: index, matching: pattern)
    }
    
    /// Returns true if the path mathes the given pattern.
    ///
    /// - Parameter pattern: The pattern to match
    /// - Returns: true if the path mathes the given pattern.
    public func pathMatches(pattern: [PathComponent]) -> Bool {
        return url?.pathMatches(pattern: pattern) ?? false
    }
}
