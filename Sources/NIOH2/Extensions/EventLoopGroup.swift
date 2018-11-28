//
//  Worker.swift
//  NIOH2
//
//  Created by Moritz Sternemann on 26.11.18.
//

import Dispatch
import NIO

extension EventLoopGroup {
    /// This group's event loop. All async work done on this worker _must_ occur on it's `EventLoop`.
    public var eventLoop: EventLoop {
        return next()
    }
    
    /// Creates a new, succeeded `EventLoopFuture` from the group's event loop with a `Void` value.
    ///
    ///     let a: EventLoopFuture<Void> = req.future()
    ///
    /// - returns: The succeeded future.
    public func future() -> EventLoopFuture<Void> {
        return self.eventLoop.newSucceededFuture(result: ())
    }
    
    /// Creates a new, succeeded `EventLoopFuture` from the group's event loop.
    ///
    ///     let a: EventLoopFuture<String> = req.future("hello")
    ///
    /// - parameters:
    ///     - value: The value that the future will wrap.
    /// - returns: The succeeded future.
    public func future<T>(_ value: T) -> EventLoopFuture<T> {
        return self.eventLoop.newSucceededFuture(result: value)
    }
    
    /// Creates a new, failed `EventLoopFuture` from the group's event loop.
    ///
    ///     let a: EventLoopFuture<String> = req.future(error: Abort(...))
    ///
    /// - parameters:
    ///     - error: The error that the future will wrap.
    /// - returns: The failed future.
    public func future<T>(error: Error) -> EventLoopFuture<T> {
        return self.eventLoop.newFailedFuture(error: error)
    }
}

