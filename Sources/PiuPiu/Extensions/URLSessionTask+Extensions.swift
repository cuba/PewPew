//
//  URLSessionTask+Extensions.swift
//  PiuPiu
//
//  Created by Jakub Sikorski on 2020-07-25.
//  Copyright © 2020 Jacob Sikorski. All rights reserved.
//

import Foundation

extension URLSessionTask {
    /// Calculates the percent sent based on `countOfBytesExpectedToSend` Returns nil if `countOfBytesExpectedToSend <= 0`
    public var percentSent: Float? {
        if countOfBytesExpectedToSend > 0 {
            return Float(Double(integerLiteral: countOfBytesSent) / Double(integerLiteral: countOfBytesExpectedToSend))
        } else {
            return nil
        }
    }
    
    /// Calculates the percent sent based on `countOfBytesExpectedToReceive` Returns nil if `countOfBytesExpectedToReceive <= 0`
    public var percentRecieved: Float? {
        if countOfBytesExpectedToReceive > 0 {
            return Float(Double(integerLiteral: countOfBytesReceived) / Double(integerLiteral: countOfBytesExpectedToReceive))
        } else {
            return nil
        }
    }
    
    /// Calculates the percent sent based on `safeCountOfBytesClientExpectsToSend` and `safeCountOfBytesClientExpectsToReceive` Returns 0 if `safeCountOfBytesClientExpectsToSend <= 0` and `safeCountOfBytesClientExpectsToReceive` <= 0
    public var percentTransferred: Float? {
        if let percentSent = self.percentSent, let percentRecieved = self.percentRecieved {
            return (percentSent + percentRecieved) / 2
        } else if let percentSent = self.percentSent {
            return percentSent
        } else {
            return percentRecieved
        }
    }
}

extension Sequence where Iterator.Element: URLSessionTask {
    /// Calculates the average percent sent for all elements that return a value for `percentSent`
    public var averagePercentSent: Float? {
        let percentages = compactMap({ $0.percentSent })
        
        if !percentages.isEmpty {
            let total = percentages.reduce(0, { $0 + $1 })
            return total / Float(percentages.count)
        } else {
            return nil
        }
    }
    
    /// Calculates the average percent sent for all elements that return a value for `percentRecieved`
    public var averagePercentRecieved: Float? {
        let percentages = compactMap({ $0.percentRecieved })
        
        if !percentages.isEmpty {
            let total = percentages.reduce(0, { $0 + $1 })
            return total / Float(percentages.count)
        } else {
            return nil
        }
    }
    
    /// Calculates the average percent sent for all elements that return a value for `percentTransferred`
    public var averagePercentTransferred: Float? {
        let percentages = compactMap({ $0.percentTransferred })
        
        if !percentages.isEmpty {
            let total = percentages.reduce(0, { $0 + $1 })
            return total / Float(percentages.count)
        } else {
            return nil
        }
    }
    
    /// Returns all tasks that have `URLSessionTask.State` of `.completed`
    public var completed: [URLSessionTask] {
        return self.filter({ $0.state == .completed })
    }
    
    /// Returns all tasks that have `URLSessionTask.State` of `.canceling`
    public var cancelling: [URLSessionTask] {
        return self.filter({ $0.state == .canceling })
    }
    
    /// Returns all tasks that have `URLSessionTask.State` of `.running`
    public var running: [URLSessionTask] {
        return self.filter({ $0.state == .running })
    }
    
    /// Returns all tasks that have `URLSessionTask.State` of `.suspended`
    public var suspended: [URLSessionTask] {
        return self.filter({ $0.state == .suspended })
    }
}
