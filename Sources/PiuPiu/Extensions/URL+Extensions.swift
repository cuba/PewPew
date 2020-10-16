//
//  URL+Extensions.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-12.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

// MARK: - Testing Extensions

extension URL {
    public static var temporaryDirectory: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }
    
    /// Returns values extracted from the path. The path must match exactly.
    ///
    /// - Parameter pattern: The pattern to match which must be exactly the same.
    /// - Returns: The matched path values. Any incosistency will return nil. The size of the array will always be the number of wildcards passed.
    public func pathValues(matching pattern: [PathComponent]) -> [PathValue]? {
        let pathStringComponents = path.components(separatedBy: "/").filter({ !$0.isEmpty })
        
        // Check the counts are the same
        guard pattern.count == pathStringComponents.count else { return nil }
        var values: [PathValue] = []
        
        for (index, pathComponent) in pattern.enumerated() {
            switch pathComponent {
            case .constant(let value):
                guard value == pathStringComponents[index] else { return nil }
                values.append(.string(pathStringComponents[index]))
            case .wildcard(let type):
                switch type {
                case .integer:
                    guard let value = Int(pathStringComponents[index]) else { return nil }
                    values.append(.integer(value))
                case .string:
                    values.append(.string(pathStringComponents[index]))
                }
            }
        }
        
        return values
    }
    
    /// Returns true if the path mathes the given pattern.
    ///
    /// - Parameter pattern: The pattern to match
    /// - Returns: true if the path mathes the given pattern.
    public func pathMatches(pattern: [PathComponent]) -> Bool {
        return pathValues(matching: pattern) != nil
    }
    
    /// Returns an integer value from the extracted path values (`PathValue`) at the given index.
    ///
    /// - Parameters:
    ///   - index: The index of the extracted value. Needs to be within the bounds of the pattern or the application will crash.
    ///   - pattern: The pattern used to extract the values
    /// - Returns: An integer value if found in the exact position of the extracted pattern.
    public func integerValue(atIndex index: Int, matching pattern: [PathComponent]) -> Int? {
        if let pathValues = pathValues(matching: pattern) {
            switch pathValues[index] {
            case .integer(let value):
                return value
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    /// Returns an string value from the extracted path values (`PathValue`) at the given index.
    ///
    /// - Parameters:
    ///   - index: The index of the extracted value. Needs to be within the bounds of the pattern or the application will crash.
    ///   - pattern: The pattern used to extract the values
    /// - Returns: An integer value if found in the exact position of the extracted pattern.
    public func stringValue(atIndex index: Int, matching pattern: [PathComponent]) -> String? {
        if let pathValues = pathValues(matching: pattern) {
            switch pathValues[index] {
            case .string(let value):
                return value
            default:
                return nil
            }
        } else {
            return nil
        }
    }
}
