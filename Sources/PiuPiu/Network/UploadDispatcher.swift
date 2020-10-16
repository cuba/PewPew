//
//  UploadDispatcher.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-07-04.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation


/// The object that will be making the API call and returning the Future
public protocol UploadDispatcher: class {
    /// Create a future to make an upload request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    ///   - data: The data to send
    /// - Returns: The promise that will send the request.
    func uploadFuture(from urlRequest: URLRequest, with data: Data) -> ResponseFuture<Response<Data?>>
}

extension UploadDispatcher {
    /// Create a future to make an upload request.
    ///
    /// - Parameters:
    ///   - data: The data to send
    ///   - callback: A callback that returns the future to send
    /// - Returns: The promise that will send the request.
    public func uploadFuture(with data: Data, from callback: @escaping () throws -> URLRequest?) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>> { [weak self] future in
            guard let self = self else { return }
            guard let urlRequest = try callback() else {
                future.cancel()
                return
            }
            
            let nestedFuture = self.uploadFuture(from: urlRequest, with: data)
            future.fulfill(by: nestedFuture)
        }
    }
}
