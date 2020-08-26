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
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This future for chaining.
    public func success(_ handler: @escaping SuccessHandler) -> ResponseFuture<T> {
        self.successHandler = handler
        return self
    }
    
    /// Attach a success handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This future for chaining.
    public func response(_ handler: @escaping SuccessHandler) -> ResponseFuture<T> {
        return success(handler)
    }
    
    /// Attach a error handler to this future that handles . Should be called before the `start()` method in case the future is fulfilled synchronously.
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
    
    /// Convert the success callback to another type.
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    /// NOTE: You should not be updating anything on UI from this thread. To be safe avoid calling self on the callback.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the callback on. The default is the main thread.
    ///   - callback: The callback to perform the transformation
    /// - Returns: The transformed future
    public func then<U>(on queue: DispatchQueue = DispatchQueue.main, _ successCallback: @escaping (T) throws -> U) -> ResponseFuture<U> {
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
    
    /// Return a new future with the results of both futures.
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func join<U>(_ callback: @escaping (T) throws -> ResponseFuture<U>?) -> ResponseFuture<(T, U)> {
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
    
    /// Handle failures by returning an object. The new future will have a success response with either the response object or the returned object in the callback
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    ///
    /// - Parameter callback: A callback to handle the error. Throwing here will result in the error callback being triggered.
    /// - Returns: A new response future with a success response with either the object or the error.
    public func thenError<U>(_ callback: @escaping (SafeResponse<T>) throws -> U) -> ResponseFuture<U> {
        return ResponseFuture<U> { future in
            self.success({ response in
                let callbackResult = try callback(.response(response))
                future.succeed(with: callbackResult)
            }).error({ error in
                do {
                    let callbackResult = try callback(.error(error))
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
    public func nonFailing() -> ResponseFuture<SafeResponse<T>> {
        return self.thenError({ response -> SafeResponse<T> in
            return response
        })
    }
    
    /// Return a new future with the results of the future retuned in the callback.
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    ///
    /// - Parameter callback: The future that returns the results we want to return.
    /// - Returns: A new response future that will contain the results
    public func replace<U>(_ successCallback: @escaping (T) throws -> ResponseFuture<U>?) -> ResponseFuture<U> {
        return ResponseFuture<U> { future in
            self.success({ response in
                guard let newPromise = try successCallback(response) else {
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
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    ///
    /// - Parameter callback: The future that returns the results we want to return.
    /// - Returns: The
    public func join<U>(_ callback: () -> ResponseFuture<U>) -> ResponseFuture<(T, U)> {
        let newFuture = callback()
        
        return ResponseFuture<(T, U)> { future in
            var firstRequestFinished = false
            var secondRequestFinished = false
            var firstObject: T?
            var secondObject: U?
            var firstError: Error?
            var secondError: Error?
            
            self.success({ response in
                firstObject = response
            }).error({ error in
                firstError = error
            }).updated({ task in
                future.update(with: task)
            }).completion({
                firstRequestFinished = true
                guard secondRequestFinished else { return }
                
                if let firstObject = firstObject, let secondObject = secondObject {
                    future.succeed(with: (firstObject, secondObject))
                } else if let error = firstError ?? secondError {
                    future.fail(with: error)
                }
            }).cancellation({
                future.cancel()
            }).send()
            
            newFuture.success({ response in
                secondObject = response
            }).updated({ task in
                future.update(with: task)
            }).error({ error in
                secondError = error
            }).completion({
                secondRequestFinished = true
                guard firstRequestFinished else { return }
                
                if let firstObject = firstObject, let secondObject = secondObject {
                    future.succeed(with: (firstObject, secondObject))
                } else if let error = firstError ?? secondError {
                    future.fail(with: error)
                }
            }).cancellation({
                future.cancel()
            }).send()
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