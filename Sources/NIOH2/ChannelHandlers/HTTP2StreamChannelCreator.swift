//
//  HTTP2StreamChannelCreator.swift
//  NIOH2
//
//  Created by Moritz Sternemann on 27.11.18.
//

import NIO
import NIOHTTP1
import NIOHTTP2

/// Internal `ChannelInboundHandler` that creates a HTTP/2 stream channel using a
/// `HTTP2StreamMultiplexer` and adds `ChannelHandler`s to it's pipeline.
internal final class HTTP2StreamChannelCreator: ChannelInboundHandler {
    /// See `ChannelInboundHandler.InboundIn`.
    typealias InboundIn = Never
    
    /// Private `HTTP2StreamMultiplexer` to create the stream channel on.
    private let multiplexer: HTTP2StreamMultiplexer
    
    /// Private list of `ChannelHandler`s to add to the stream channel.
    private let handlers: [ChannelHandler]
    
    /// Creates a new `HTTP2StreamChannelCreator`.
    ///
    /// - parameters:
    ///     - multiplexer: Stream multiplexer to create the stream channel on.
    ///     - handlers: List of handlers to add to the stream channel.
    init(multiplexer: HTTP2StreamMultiplexer, handlers: [ChannelHandler] = []) {
        self.multiplexer = multiplexer
        self.handlers = handlers
    }
    
    /// See `ChannelInboundHandler.channelActive(ctx:)`.
    func channelActive(ctx: ChannelHandlerContext) {
        self.multiplexer.createStreamChannel(promise: nil, requestStreamInitializer)
    }
    
    /// Callback for `HTTP2StreamMultiplexer.createStreamChannel(promise:_:)`.
    /// Adds a `HTTP2ToHTTP1ClientCodec and all handlers to the channels pipeline.
    /// - parameters:
    ///     - channel: Current channel.
    ///     - streamID: HTTP/2 stream id of the created stream.
    /// - returns: A future that resolves when all handlers have been added to the pipeline.
    private func requestStreamInitializer(channel: Channel, streamID: HTTP2StreamID) -> EventLoopFuture<Void> {
        return channel.pipeline.addHandlers([HTTP2ToHTTP1ClientCodec(streamID: streamID, httpProtocol: .https)] + handlers, first: false)
    }
}
