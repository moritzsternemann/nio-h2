//
//  EventLoopFuture+Map.swift
//  NIOH2
//
//  Created by Moritz Sternemann on 26.11.18.
//

import NIO

extension EventLoopFuture {
    /// Maps a `EventLoopFuture` to a `EventLoopFuture` of a different type.
    ///
    /// - note: The result returned within should be non-`EventLoopFuture`type.
    ///
    ///     print(futureString) // EventLoopFuture<String>
    ///     let futureInt = futureString.map(to: Int.self) { string in
    ///         print(string) // The actual string
    ///         return Int(string) ?? 0
    ///     }
    ///     print(futureInt) // EventLoopFuture<Int>
    ///
    /// See `flatMap(to:_:)` for mapping `EventLoopFuture` results to other `EventLoopFuture` types.
    public func map<T>(to type: T.Type = T.self, _ callback: @escaping (Expectation) throws -> T) -> EventLoopFuture<T> {
        let promise: EventLoopPromise<T> = eventLoop.newPromise()
        
        self.do { expectation in
            do {
                let mapped = try callback(expectation)
                promise.succeed(result: mapped)
            } catch {
                promise.fail(error: error)
            }
        }.catch { error in
            promise.fail(error: error)
        }
        
        return promise.futureResult
    }
    
    /// Maps a `EventLoopFuture` to a `EventLoopFuture` of a different type.
    ///
    /// - note: The result returned within the closure should be another `EventLoopFuture`.
    ///
    ///     print(futureURL) // EventLoopFuture<URL>
    ///     let futureRes = futureURL.map(to: Response.self) { url in
    ///         print(url) // The actual URL
    ///         return client.get(url: url) // Returns EventLoopFuture<Response>
    ///     }
    ///     print(futureRes // EventLoopFuture<Response>
    ///
    /// See `map(to:_:)` for mapping `EventLoopFuture` results to non-`EventLoopFuture` types.
    public func flatMap<T>(to type: T.Type = T.self, _ callback: @escaping (Expectation) throws -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        let promise: EventLoopPromise<T> = eventLoop.newPromise()
        
        self.do { expectation in
            do {
                let mapped = try callback(expectation)
                mapped.cascade(promise: promise)
            } catch {
                promise.fail(error: error)
            }
        }.catch { error in
            promise.fail(error: error)
        }
        
        return promise.futureResult
    }
}
