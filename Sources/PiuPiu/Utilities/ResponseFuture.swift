//
//  ResponseFuture.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-02-15.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A ResponseFuture is a delayed action that is performed after calling `start()`.
public class ResponseFuture<T> {
    public typealias ActionCallback = (ResponseFuture<T>) throws -> Void
    public typealias SuccessHandler = (T) throws -> Void
    public typealias ErrorHandler = (Error) -> Void
    public typealias CompletionHandler = () -> Void
    public typealias TaskCallback = (URLSessionTask) -> Void
    public typealias CancellationHandler = () -> Void
    
    public enum Status {
        case created
        case started
        case success
        case error
        case cancelled
        
        var isComplete: Bool {
            switch self {
            case .created   : return false
            case .started   : return false
            case .success   : return true
            case .error     : return true
            case .cancelled : return true
            }
        }
    }
    
    private var action: ActionCallback?
    private var successHandler: SuccessHandler?
    private var errorHandler: ErrorHandler?
    private var completionHandler: CompletionHandler?
    private var taskCallback: TaskCallback?
    private var cancellationHandler: CancellationHandler?
    
    /// The status of the future.
    private(set) public var status: Status
    
    /// Initialize the future with an action that is triggered when calling the start() method.
    ///
    /// - Parameter action: The action that is performed. The action returns this future when triggered.
    public init(action: @escaping ActionCallback) {
        self.action = action
        self.status = .created
    }
    
    /// Initialize the future with an result that triggers the success callback as soon as `send` or `start` is called.
    ///
    /// - Parameter result: The result that is returned right away.
    public convenience init(result: T) {
        self.init { future in
            future.succeed(with: result)
        }
    }
    
    /// Fulfills the given future with the results of this future. Both futures have to be of the same type.
    ///
    /// - Parameter future: The future to be fulfilled.
    private func fulfill(_ future: ResponseFuture<T>) {
        self.success({ result in
            future.succeed(with: result)
        }).updated({ task in
            future.update(with: task)
        }).error({ error in
            future.fail(with: error)
        }).send()
    }
    
    /// Fulfills this future with the results of the given future. Both futures have to be of the same type.
    ///
    /// - Parameter future: The future to be fulfilled.
    public func fulfill(by future: ResponseFuture<T>) {
        future.fulfill(self)
    }
    
    /// Fulfills this future with the results of the given future. Both futures have to be of the same type.
    ///
    /// - Parameter future: The future to be fulfilled.
    @available(*, deprecated, renamed: "fulfill(by:)")
    public func fulfill(with future: ResponseFuture<T>) {
        future.fulfill(self)
    }
    
    /// Fullfill this future with a successful result.
    ///
    /// - Parameter object: The succeeded object required by the future success callback.
    public func succeed(with object: T) {
        DispatchQueue.main.async {
            do {
                try self.successHandler?(object)
                self.status = .success
                self.completionHandler?()
                self.finalize()
            } catch {
                self.fail(with: error)
            }
        }
    }
    
    /// Fullfill the future with a failed result.
    ///
    /// - Parameter object: The failed object required by the future error callback.
    public func fail(with error: Error) {
        DispatchQueue.main.async {
            self.errorHandler?(error)
            self.status = .error
            self.completionHandler?()
            self.finalize()
        }
    }
    
    /// Cancel this future. The cancellation and completion callbacks will be triggered on this future and no further callbacks will be triggered. This method does not cancel the URLSessionTask itself. When manually creating a wrapped ResponseFuture, you need to make sure you call cancel on the new future to continue the cancellation chain.
    public func cancel() {
        DispatchQueue.main.async {
            self.cancellationHandler?()
            self.status = .cancelled
            self.completionHandler?()
            self.finalize()
        }
    }
    
    /// Clears all callbacks to avoid memory leaks
    private func finalize() {
        action = nil
        successHandler = nil
        errorHandler = nil
        taskCallback = nil
        cancellationHandler = nil
    }
    
    /// Update the progress of this future.
    ///
    /// - Parameter progress: The progress of this future between 0 and 1 where 0 is 0% and 1 being 100%
    public func update(with task: URLSessionTask) {
        DispatchQueue.main.async {
            self.taskCallback?(task)
        }
    }
    
    /// Attach a success handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This future for chaining.
    public func updated(_ callback: @escaping TaskCallback) -> ResponseFuture<T> {
        self.taskCallback = callback
        return self
    }
    
    /// Attach a success handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    /// **DO NOT** use `result` callback in conjunction with this callback.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This future for chaining.
    public func success(_ handler: @escaping SuccessHandler) -> ResponseFuture<T> {
        self.successHandler = handler
        return self
    }
    
    /// Attach a success handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    /// **DO NOT** use `success` or `result` callbacks in conjunction with this callback.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This future for chaining.
    public func response(_ handler: @escaping SuccessHandler) -> ResponseFuture<T> {
        return success(handler)
    }
    
    /// Attach an error handler to this future that handles . Should be called before the `start()` method in case the future is fulfilled synchronously.
    /// **DO NOT** use `result` callback in conjunction with this callback.
    ///
    /// - Parameter handler: The error handler that will be triggered if anything is thrown inside the success callback.
    /// - Returns: This future for chaining.
    public func error(_ handler: @escaping ErrorHandler) -> ResponseFuture<T> {
        self.errorHandler = handler
        return self
    }
    
    /// Attach a completion handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    ///
    /// - Parameter handler: The completion handler that will be triggered after the `succeed()` or `fail()` methods are triggered.
    /// - Returns: This future for chaining.
    public func completion(_ handler: @escaping CompletionHandler) -> ResponseFuture<T> {
        self.completionHandler = handler
        return self
    }
    
    /// Attach a completion handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    ///
    /// - Parameter handler: The completion handler that will be triggered after the `succeed()` or `fail()` methods are triggered.
    /// - Returns: This future for chaining.
    public func cancellation(_ handler: @escaping CancellationHandler) -> ResponseFuture<T> {
        self.cancellationHandler = handler
        return self
    }
    
    /// Attach a result handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    /// **DO NOT** use `success` or `error` callbacks in conjunction with this callback.
    ///
    /// - Parameter handler: The completion handler that will be triggered after the `succeed()` or `fail()` methods are triggered.
    /// - Returns: This future for chaining.
    public func result(_ handler: @escaping (Result<T, Error>) -> Void) -> ResponseFuture<T> {
        self.success { response in
            handler(.success(response))
        }.error { error in
            handler(.failure(error))
        }
    }
    
    /// Convert the success callback to another type.
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    /// NOTE: You should not be updating anything on UI from this thread. To be safe avoid calling self on the callback.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the callback on. The default is the main thread.
    ///   - callback: The callback to perform the transformation
    /// - Returns: The transformed future
    public func map<U>(_ type: U.Type, on queue: DispatchQueue = DispatchQueue.main, successCallback: @escaping (T) throws -> U) -> ResponseFuture<U> {
        return ResponseFuture<U> { future in
            self.success({ result in
                queue.async {
                    do {
                        let transformed = try successCallback(result)
                        future.succeed(with: transformed)
                    } catch {
                        future.fail(with: error)
                    }
                }
            }).updated({ task in
                future.update(with: task)
            }).error({ error in
                future.fail(with: error)
            }).cancellation({
                future.cancel()
            }).send()
        }
        
    }
    
    /// Convert the success callback to another type.
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    /// NOTE: You should not be updating anything on UI from this thread. To be safe avoid calling self on the callback.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the callback on. The default is the main thread.
    ///   - callback: The callback to perform the transformation
    /// - Returns: The transformed future
    public func then<U>(on queue: DispatchQueue = DispatchQueue.main, _ successCallback: @escaping (T) throws -> U) -> ResponseFuture<U> {
        return map(U.self, on: queue, successCallback: successCallback)
    }
    
    /// Convert the success callback to another type.
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    /// NOTE: You should not be updating anything on UI from this thread. To be safe avoid calling self on the callback.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the callback on. The default is the main thread.
    ///   - callback: The callback to perform the transformation
    /// - Returns: The transformed future
    public func then<U>(_ type: U.Type, on queue: DispatchQueue = DispatchQueue.main, _ successCallback: @escaping (T) throws -> U) -> ResponseFuture<U> {
        return map(type, on: queue, successCallback: successCallback)
    }
    
    /// Return a new future with the results of both futures.
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    @available(*, deprecated, renamed: "seriesJoin")
    public func join<U>(_ callback: @escaping (T) throws -> ResponseFuture<U>?) -> ResponseFuture<(T, U)> {
        return seriesJoin(U.self, callback: callback)
    }
    
    /// Handle failures by returning an object. The new future will have a success response with either the response object or the returned object in the callback
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    ///
    /// - Parameter callback: A callback to handle the error. Throwing here will result in the error callback being triggered.
    /// - Returns: A new response future with a success response with either the object or the error.
    @available(*, deprecated, renamed: "thenResult")
    public func thenError<U>(_ callback: @escaping (SafeResponse<T>) throws -> U) -> ResponseFuture<U> {
        return thenResult(U.self) { result in
            switch result {
            case .success(let value):
                return try callback(.response(value))
            case .failure(let error):
                return try callback(.error(error))
            }
        }
    }
    
    /// Allows the error to fail by returning a success response with either the original response or the error
    ///
    /// - Returns: A new future containing the original response or an error object.
    @available(*, deprecated, renamed: "safeResult")
    public func nonFailing() -> ResponseFuture<SafeResponse<T>> {
        return self.thenResult(SafeResponse<T>.self) { result in
            switch result {
            case .success(let value):
                return SafeResponse.response(value)
            case .failure(let error):
                return SafeResponse.error(error)
            }
        }
    }
    
    /// Allows the error to fail by returning a success response with either the original response or the error
    ///
    /// - Returns: A new future containing the original response or an error object.
    public func thenResult<U>(_ type: U.Type, callback: @escaping (Result<T, Error>) throws -> U) -> ResponseFuture<U> {
        return ResponseFuture<U> { future in
            self.success({ response in
                let callbackResult = try callback(.success(response))
                future.succeed(with: callbackResult)
            }).error({ error in
                do {
                    let callbackResult = try callback(.failure(error))
                    future.succeed(with: callbackResult)
                } catch let newError {
                    future.fail(with: newError)
                }
            }).updated({ task in
                future.update(with: task)
            }).cancellation({
                future.cancel()
            }).send()
        }
    }
    
    /// Allows the error to fail by returning a success response with either the original response or the error
    ///
    /// - Returns: A new future containing the original response or an error object.
    public func safeResult() -> ResponseFuture<Result<T, Error>> {
        return ResponseFuture<Result<T, Error>>() { future in
            self.success { response in
                future.succeed(with: .success(response))
            }
            .error { error in
                future.succeed(with: .failure(error))
            }
            .updated{ task in
                future.update(with: task)
            }
            .send()
        }
    }
    
    /// Return a new future with the results of the future retuned in the callback.
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    ///
    /// - Parameter callback: The future that returns the results we want to return.
    /// - Returns: A new response future that will contain the results
    @available(*, deprecated, message: "This was replaced with a method that takes an explicit type.")
    public func replace<U>(_ successCallback: @escaping (T) throws -> ResponseFuture<U>?) -> ResponseFuture<U> {
        return replace(U.self, callback: successCallback)
    }
    
    /// Return a new future with the results of both futures making both calls in series
    /// WARNING: Returning `nil` on the callback will cause all the requests to be cancelled and the cancellation callback to be triggered.
    ///
    /// - Parameter callback: The future that returns the results we want to return.
    /// - Returns: A new response future that will contain the results
    public func replace<U>(_ type: U.Type, callback: @escaping (T) throws -> ResponseFuture<U>?) -> ResponseFuture<U> {
        return ResponseFuture<U> { future in
            self.success({ response in
                guard let newPromise = try callback(response) else {
                    future.cancel()
                    return
                }
                
                newPromise.success({ newResponse in
                    future.succeed(with: newResponse)
                }).updated({ task in
                    future.update(with: task)
                }).error({ error in
                    future.fail(with: error)
                }).cancellation({
                    future.cancel()
                }).send()
            }).error({ error in
                future.fail(with: error)
            }).updated({ task in
                future.update(with: task)
            }).cancellation({
                future.cancel()
            }).send()
        }
    }
    
    /// Return a new future with the results of the future retuned in the callback.
    ///
    /// - Parameter callback: The future that returns the results we want to return.
    /// - Returns: The
    @available(*, deprecated, renamed: "parallelJoin")
    public func join<U>(_ callback: () -> ResponseFuture<U>) -> ResponseFuture<(T, U)> {
        return parallelJoin(U.self, callback: callback)
    }
    
    /// Return a new future with the results of both futures making both calls in parallel
    /// WARNING: Returning `nil` on the callback will cause all the requests to be cancelled and the cancellation callback to be triggered.
    ///
    /// - Parameter callback: The callback that contains the results of the original future
    /// - Returns: A new future with the results of both futures
    public func seriesJoin<U>(_ type: U.Type, callback: @escaping (T) throws -> ResponseFuture<U>?) -> ResponseFuture<(T, U)> {
        return ResponseFuture<(T, U)> { future in
            self.success({ response in
                guard let newFuture = try callback(response) else {
                    future.cancel()
                    return
                }
                
                newFuture.success({ newResponse in
                    future.succeed(with: (response, newResponse))
                }).error({ error in
                    future.fail(with: error)
                }).updated({ task in
                    future.update(with: task)
                }).cancellation({
                    future.cancel()
                }).send()
            }).error({ error in
                future.fail(with: error)
            }).updated({ task in
                future.update(with: task)
            }).cancellation({
                future.cancel()
            }).send()
        }
    }
    
    /// Return a new future with the results of both futures making both calls in parallel
    ///
    /// - Parameter callback: The future that returns the results we want to return.
    /// - Returns: The new future with both responses
    public func parallelJoin<U>(_ type: U.Type, callback: () -> ResponseFuture<U>) -> ResponseFuture<(T, U)> {
        let newFuture = callback()
        
        return ResponseFuture<(T, U)> { future in
            var firstResponse: T?
            var secondResponse: U?
            
            self.success({ response in
                guard let secondResponse = secondResponse else {
                    firstResponse = response
                    return
                }
                
                future.succeed(with: (response, secondResponse))
            }).error({ error in
                future.fail(with: error)
            }).updated({ task in
                future.update(with: task)
            }).cancellation({
                future.cancel()
            }).send()
            
            newFuture.success({ response in
                guard let firstResponse = firstResponse else {
                    secondResponse = response
                    return
                }
                
                future.succeed(with: (firstResponse, response))
            }).error({ error in
                future.fail(with: error)
            }).updated({ task in
                future.update(with: task)
            }).cancellation({
                future.cancel()
            }).send()
        }
    }
    
    /// Return a new future with the results of both futures making both calls in series
    /// Returning `nil` on the callback does **not** cancel the requests
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func seriesNullableJoin<U>(_ type: U.Type, callback: @escaping (T) throws -> ResponseFuture<U>?) -> ResponseFuture<(T, U?)> {
        return ResponseFuture<(T, U?)> { future in
            self.success({ response in
                guard let newFuture = try callback(response) else {
                    future.succeed(with: (response, nil))
                    return
                }
                
                newFuture.success({ newResponse in
                    future.succeed(with: (response, newResponse))
                }).error({ error in
                    future.fail(with: error)
                }).updated({ task in
                    future.update(with: task)
                }).cancellation({
                    future.cancel()
                }).send()
            }).error({ error in
                future.fail(with: error)
            }).updated({ task in
                future.update(with: task)
            }).cancellation({
                future.cancel()
            }).send()
        }
    }
    
    /// Return a new future with the results of both futures making both calls in parallel
    /// Returning `nil` on the callback does **not** cancel the requests
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func parallelNullableJoin<U>(_ type: U.Type, callback: () -> ResponseFuture<U>?) -> ResponseFuture<(T, U?)> {
        if let future = callback() {
            return parallelJoin(type) {
                return future
            }.then((T, U?).self) { result in
                return (result.0, result.1 as U?)
            }
        } else {
            return then((T, U?).self) { result in
                return (result, nil)
            }
        }
    }
    
    /// Return a new future with the results of both futures making both calls in series
    /// WARNING: Returning `nil` on the callback will cause all the requests to be cancelled and the cancellation callback to be triggered.
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func safeSeriesJoin<U>(_ type: U.Type, callback: @escaping (T) throws -> ResponseFuture<U>?) -> ResponseFuture<(T, Result<U, Error>)> {
        return seriesJoin(Result<U, Error>.self) { result in
            return try callback(result)?.safeResult()
        }
    }
    
    /// Return a new future with the results of both futures making both calls in parallel
    /// Returning `nil` on the callback does **not** cancel the requests
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func safeParallelJoin<U>(_ type: U.Type, callback: () -> ResponseFuture<U>) -> ResponseFuture<(T, Result<U, Error>)> {
        return parallelJoin(Result<U, Error>.self, callback: {
            return callback().safeResult()
        })
    }
    
    /// Return a new future with the results of both futures making both calls in parallel
    /// Returning `nil` on the callback does **not** cancel the requests
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func safeSeriesNullableJoin<U>(_ type: U.Type, callback: @escaping (T) throws -> ResponseFuture<U>?) -> ResponseFuture<(T, Result<U, Error>?)> {
        return seriesNullableJoin(Result<U, Error>.self) { result in
            return try callback(result)?.safeResult()
        }
    }
    
    /// Return a new future with the results of both futures making both calls in series
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func safeParallelNullableJoin<U>(_ type: U.Type, callback: () -> ResponseFuture<U>?) -> ResponseFuture<(T, Result<U, Error>?)> {
        return parallelNullableJoin(Result<U, Error>.self) {
            return callback()?.safeResult()
        }
    }
    
    /// This method triggers the action method defined on this future.
    public func start() {
        self.status = .started
        
        do {
            try action?(self)
            action = nil
        } catch {
            fail(with: error)
        }
    }
    
    /// This method triggers the action method defined on this future.
    public func send() {
        start()
    }
}

public extension ResponseFuture where T: Sequence {
    /// Conveniently call a  future in parallel and append its results into this future where the result of the future is a sequence and the result of the given future is an element of that sequence.
    func addingParallelResult(from callback: () -> ResponseFuture<T.Element>) -> ResponseFuture<[T.Element]> {
        return parallelJoin(T.Element.self, callback: callback)
            .map([T.Element].self) { (sequence, element) in
                var result = Array(sequence)
                result.append(element)
                return result
            }
    }
    
    /// Conveniently call a  future in series and append its results into this future where the result of the future is a sequence and the result of the given future is an element of that sequence.
    /// WARNING: Returning `nil` on the callback will cause all the requests to be cancelled and the cancellation callback to be triggered.
    func addingSeriesResult(from callback: @escaping (T) throws -> ResponseFuture<T.Element>?) -> ResponseFuture<[T.Element]> {
        return seriesJoin(T.Element.self, callback: callback)
            .map([T.Element].self) { (sequence, element) in
                var result = Array(sequence)
                result.append(element)
                return result
            }
    }
    
    /// Conveniently call a  future in parallel and append its results into this future where the result of the future is a sequence and the result of the given future is an element of that sequence.
    func addingParallelNullableResult(from callback: () -> ResponseFuture<T.Element>?) -> ResponseFuture<[T.Element]> {
        return parallelNullableJoin(T.Element.self, callback: callback)
            .map([T.Element].self) { (sequence, element) in
                var result = Array(sequence)
                
                if let element = element {
                    result.append(element)
                }
                
                return result
            }
    }
    
    /// Conveniently call a  future in series and append its results into this future where the result of the future is a sequence and the result of the given future is an element of that sequence.
    /// Returning `nil` on the callback does **not** cancel the requests
    func addingSeriesNullableResult(from callback: @escaping (T) throws -> ResponseFuture<T.Element>?) -> ResponseFuture<[T.Element]> {
        return seriesNullableJoin(T.Element.self, callback: callback)
            .map([T.Element].self) { (sequence, element) in
                var result = Array(sequence)
                
                if let element = element {
                    result.append(element)
                }
                
                return result
            }
    }
}
