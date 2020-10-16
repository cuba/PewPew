//
//  DateFormatter+Extensions.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-03-01.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

extension DateFormatter {
    /// A formatter using the following format: `yyyy-MM-dd'T'HH:mm:ssZZZZZ`
    public static let rfc3339: DateFormatter = {
        let rfc3339DateFormatter = DateFormatter()
        rfc3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rfc3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        rfc3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return rfc3339DateFormatter
    }()
}
