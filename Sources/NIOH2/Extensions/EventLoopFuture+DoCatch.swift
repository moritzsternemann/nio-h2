//
//  EventLoopFuture+DoCatch.swift
//  NIOH2
//
//  Created by Moritz Sternemann on 26.11.18.
//

import NIO

extension EventLoopFuture {
    /// Adds a callback for handling this `EventLoopFuture`'s result when it becomes available.
    ///
    ///     futureString.do { string in
    ///         print(string)
    ///     }.catch { error in
    ///         print("oops: \(error)")
    ///     }
    ///
    /// - warning: Don't forget to use `catch` to handle the error case.
    public func `do`(_ callback: @escaping (T) -> ()) -> EventLoopFuture<T> {
        whenSuccess(callback)
        return self
    }
    
    /// Adds a callback for handling this `EventLoopFuture`'s result if an error occurs.
    ///
    ///     futureString.do { string in
    ///         print(string)
    ///     }.catch { error in
    ///         print("oops: \(error)")
    ///     }
    ///
    /// - note: Will *only* be executed if an error occurs. Successful results will not call this handler.
    @discardableResult
    public func `catch`(_ callback: @escaping (Error) -> ()) -> EventLoopFuture<T> {
        whenFailure(callback)
        return self
    }
    
    /// Adds a handler to be asynchronously executed on completion of this future.
    ///
    ///     futureString.do { string in
    ///         print(string)
    ///     }.catch { error in
    ///         print("oops: \(error)")
    ///     }.always {
    ///         print("done")
    ///     }
    ///
    /// - note: Wille be executed on both success and failure, but will not receive any input.
    @discardableResult
    public func always(_ callback: @escaping () -> ()) -> EventLoopFuture<T> {
        whenComplete(callback)
        return self
    }
}
