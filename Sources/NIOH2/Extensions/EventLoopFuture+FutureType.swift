//
//  FutureType.swift
//  NIOH2
//
//  Created by Moritz Sternemann on 27.11.18.
//

import NIO

/// A future result type.
public protocol FutureType {
    associatedtype Expectation
}

extension EventLoopFuture: FutureType {
    /// See `FutureType`.
    public typealias Expectation = T
}
