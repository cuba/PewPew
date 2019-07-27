//
//  DocumentationExamples.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-02-20.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import Example
@testable import PiuPiu

class DocumentationExamples: XCTestCase {
    private var strongFuture: ResponseFuture<Post>?
    
    private let dispatcher = MockURLRequestDispatcher(delay: 0, callback: { request in
        if let id = request.integerValue(atIndex: 1, matching: [.constant("posts"), .wildcard(type: .integer)]) {
            let post = Post(id: id, userId: 123, title: "Some post", body: "Lorem ipsum ...")
            return try Response.makeMockJSONResponse(with: request, encodable: post, statusCode: .ok)
        } else if let id = request.integerValue(atIndex: 1, matching: [.constant("users"), .wildcard(type: .integer)]) {
            let user = User(id: id, name: "Jim Halpert")
            return try Response.makeMockJSONResponse(with: request, encodable: user, statusCode: .ok)
        } else if request.pathMatches(pattern: [.constant("posts")]) {
            let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
            return try Response.makeMockJSONResponse(with: request, encodable: [post], statusCode: .ok)
        } else if request.pathMatches(pattern: [.constant("users")]) {
            let user = User(id: 123, name: "Jim Halpert")
            return try Response.makeMockJSONResponse(with: request, encodable: [user], statusCode: .ok)
        } else {
            throw ResponseError.notFound
        }
    })
    
    func testSimpleRequest() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request).response({ response in
            // Handles any responses including negative responses such as 4xx and 5xx
            
            // The error object is available if we get an
            // undesirable status code such as a 4xx or 5xx
            if let error = response.error {
                // Throwing an error in any callback will trigger the `error` callback.
                // This allows us to pool all failures in one place.
                throw error
            }
            
            let post = try response.decode(Post.self)
            // Do something with our deserialized object
            // ...
            print(post)
        }).error({ error in
            // Handles any errors during the request process,
            // including all request creation errors and anything
            // thrown in the `then` or `success` callbacks.
        }).completion({
            // The completion callback is guaranteed to be called once
            // for every time the `start` method is triggered on the future.
        }).send()
    }

    func testGetPostExample() {
        // Expectations
        let responseExpectation = self.expectation(description: "Response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let errorExpectation = self.expectation(description: "Error triggered")
        
        responseExpectation.expectedFulfillmentCount = 1
        completionExpectation.expectedFulfillmentCount = 1
        errorExpectation.isInverted = true
        
        // This is how we handle a request future
        getPost(id: 1).response({ response in
            // Handle the success which will give your posts.
            responseExpectation.fulfill()
        }).error({ error in
            // Triggers whenever an error is thrown.
            // This includes deserialization errors, unwraping failures, and anything else that is thrown
            // in a any other throwable callback.
            errorExpectation.fulfill()
        }).completion({
            // Always triggered at the very end to inform you this future has been satisfied.
            completionExpectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    private func getPost(id: Int) -> ResponseFuture<Post> {
        // We create a future and tell it to transform the response using the
        // `then` callback. After this we can return this future so the callbacks will
        // be triggered using the transformed object. We may re-use this method in different
        return dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!
            return URLRequest(url: url, method: .get)
        }).then({ response -> Post in
            if let error = response.error {
                // The error is available when a non-2xx response comes in
                // Such as a 4xx or 5xx
                // You may also parse a custom error object here.
                throw error
            } else {
                // Return the decoded object. If an error is thrown while decoding,
                // It will be caught in the `error` callback.
                return try response.decode(Post.self)
            }
        })
    }
    
    func testWrapEncodingInAFuture() {
        // Expectations
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        // When
        dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            var request = URLRequest(url: url, method: .post)
            try request.setJSONBody(post)
            return request
        }).error({ error in
            // Any error thrown while creating the request will trigger this callback.
        }).completion({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFullResponseFutureExample() {
        dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).then({ response -> Post in
            // Handles any responses and transforms them to another type
            // This includes negative responses such as 400s and 500s
            
            if let error = response.error {
                // We throw the error so we can handle it in the `error` callback.
                // We can also handle the error response in a more custom way if we chose.
                throw error
            } else {
                // if we have no error, we just return the decoded object
                // If anything is thrown, it will be caught in the `error` callback.
                return try response.decode(Post.self)
            }
        }).response({ post in
            // Handles any success responses.
            // In this case the object returned in the `then` method.
        }).error({ error in
            // Handles any errors during the request process,
            // including all request creation errors and anything
            // thrown in the `then` or `success` callbacks.
        }).completion({
            // The completion callback guaranteed to be called once
            // for every time the `start` method is triggered on the callback.
        }).send()
    }
    
    func testWeakCallbacks() {
        // Expectations
        let expectation = self.expectation(description: "Success response triggered")
        
        dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).then({ response -> Post in
            return try response.decode(Post.self)
        }).response({ [weak self] post in
            // [weak self] needed as `self` is called
            self?.show(post)
        }).completion({
            // [weak self] needed as `self` is called
            // You can use an optional self directly.
            expectation.fulfill()
        }).send()
        
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWeakCallbacksStrongReference() {
        // Expectations
        let expectation = self.expectation(description: "Success response triggered")
        
        self.strongFuture = dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).then({ response -> Post in
            // [weak self] not needed as `self` is not called
            return try response.decode(Post.self)
        }).response({ [weak self] post in
            // [weak self] needed as `self` is called
            self?.show(post)
        }).completion({ [weak self] in
            // [weak self] needed as `self` is called
            self?.strongFuture = nil
            expectation.fulfill()
        })
        
        // Perform other logic, add delay, do whatever you would do that forced you
        // to store a reference to this future in the first place
        
        self.strongFuture?.send()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWeakCallbacksWeakReferenceDealocated() {
        // Expectations
        let expectation = self.expectation(description: "Success response should not be triggered")
        expectation.isInverted = true
        
        weak var weakFuture: ResponseFuture<Response<Data?>>? = dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).completion({
            // [weak self] needed as `self` is not called
            expectation.fulfill()
        })
        
        // Our object is already nil because we have not established a strong reference to it.
        // The `send` method will do nothing. No callback will be triggered.
        
        XCTAssertNil(weakFuture)
        weakFuture?.send()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSeriesJoin() {
        let expectation = self.expectation(description: "Success response triggered")
        
        dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).then({ response in
            // Transform this response so that we can reference it in the join callback.
            return try response.decode(Post.self)
        }).join({ [weak self] post -> ResponseFuture<User>? in
            guard let self = self else {
                // We used [weak self] because our dispatcher is referenced on self.
                // Returning nil will cancel execution of this promise
                // and triger the `cancellation` and `completion` callbacks.
                // Do this check to prevent memory leaks.
                return nil
            }
            
            // Joins a future with another one returning both results.
            // The post is passed so it can be used in the second request.
            // In this case, we take the user ID of the post to construct our URL.
            let url = URL(string: "https://jsonplaceholder.typicode.com/users/\(post.userId)")!
            let request = URLRequest(url: url, method: .get)
            
            return self.dispatcher.dataFuture(from: request).then({ response -> User in
                return try response.decode(User.self)
            })
        }).success({ post, user in
            // The final response callback includes both results.
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testParallelJoin() {
        let expectation = self.expectation(description: "Success response triggered")
        
        dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
            return URLRequest(url: url, method: .get)
        }).then({ response in
            return try response.decode([Post].self)
        }).join({ () -> ResponseFuture<[User]> in
            // Joins a future with another one returning both results.
            // Since this callback is non-escaping, you don't have to use [weak self]
            let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
            let request = URLRequest(url: url, method: .get)
            
            return self.dispatcher.dataFuture(from: request).then({ response -> [User] in
                return try response.decode([User].self)
            })
        }).success({ posts, users in
            // The final response callback includes both results.
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testCustomFuture() {
        // Expectations
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        let image = UIImage()
        
        resize(image: image).success({ resizedImage in
            // Handle success
        }).error({ error in
            // Handle error
        }).completion({
            // Handle completion
            completionExpectation.fulfill()
        }).start()
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    private func resize(image: UIImage) -> ResponseFuture<UIImage> {
        return ResponseFuture<UIImage>(action: { future in
            // This is an example of how a future is executed and fulfilled.
            DispatchQueue.global(qos: .background).async {
                // lets make an expensive operation on a background thread.
                // The success and progress and error callbacks will be synced on the main thread
                // So no need to sync back to the main thread.
                
                do {
                    // Do an expensive operation here ....
                    let resizedImage = try image.resize(ratio: 16/9)
                    
                    // If possible, we can send smaller progress updates
                    // Otherwise it's a good idea to send 1 to indicate this task is all finished.
                    // Not sending this won't cause any harm but your progress callback will not be triggered as a result of this future.
                    future.update(progress: 1)
                    future.succeed(with: resizedImage)
                } catch {
                    future.fail(with: error)
                }
            }
        })
    }
    
    
    
    private func show(_ post: Post) {
        print(post)
    }
}

extension UIImage {
    func resize(ratio: CGFloat) throws -> UIImage {
        return self
    }
}
