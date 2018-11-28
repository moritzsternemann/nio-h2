//
//  HTTPClientRequestSerializer.swift
//  NIOH2
//
//  Created by Moritz Sternemann on 27.11.18.
//

import NIO
import NIOHTTP1
import NIOHTTP2

/// Internal `ChannelOutboundHandler` that serializes `HTTPRequest` to `HTTPClientRequestPart`.
internal final class HTTP2ClientRequestSerializer: ChannelOutboundHandler {
    /// See `ChannelOutboundHandler.OutboundIn`.
    typealias OutboundIn = HTTPRequest

    /// See `ChannelOutboundHandler.OutboundOut`.
    typealias OutboundOut = HTTPClientRequestPart

    /// Hostname we are serializing responses to.
    private let hostname: String

    /// Creates a new `HTTP2ClientRequestSerializer`.
    init(hostname: String) {
        self.hostname = hostname
    }

    /// See `ChannelOutboundHandler.write(ctx:data:promise:)`.
    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let req = unwrapOutboundIn(data)
        var headers = req.headers
        headers.add(name: .host, value: hostname)
        headers.replaceOrAdd(name: .userAgent, value: "APNSClient/1.0 (Swift)")
        var httpHead = HTTPRequestHead(version: req.version, method: req.method, uri: req.url.absoluteString)
        httpHead.headers = headers
        ctx.write(wrapOutboundOut(.head(httpHead)), promise: nil)
        if let data = req.body.data {
            var buffer = ByteBufferAllocator().buffer(capacity: data.count)
            buffer.write(bytes: data)
            ctx.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        }
        ctx.write(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
}
