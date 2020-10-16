//
//  DateEncodingStrategy+Extensions.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-03-01.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

extension JSONEncoder.DateEncodingStrategy {
    /// A date encoding strategy that uses the RFC3339 encoding format
    public static var rfc3339: JSONEncoder.DateEncodingStrategy {
        return JSONEncoder.DateEncodingStrategy.formatted(DateFormatter.rfc3339)
    }
}

extension JSONDecoder.DateDecodingStrategy {
    /// A date decoding strategy that uses the RFC3339 encoding format
    public static var rfc3339: JSONDecoder.DateDecodingStrategy {
        return JSONDecoder.DateDecodingStrategy.formatted(DateFormatter.rfc3339)
    }
}
