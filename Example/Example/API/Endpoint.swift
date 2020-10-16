//
//  Endpoint.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-07-12.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import PiuPiu

enum Endpoint: URLEndpoint {
    case posts
    case post(id: Int)
    
    var path: [PathValue] {
        switch self {
        case .posts:
            return [.string("posts")]
        case .post(let id):
            return [.string("posts"), .integer(id)]
        }
    }
}

protocol URLEndpoint {
    var path: [PathValue] { get }
}

extension URLEndpoint {
    var pathString: String {
        return path.string
    }
}
