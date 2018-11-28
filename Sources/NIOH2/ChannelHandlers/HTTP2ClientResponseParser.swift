//
//  HTTP2ClientResponseParser.swift
//  NIOH2
//
//  Created by Moritz Sternemann on 27.11.18.
//

import Foundation
import NIO
import NIOHTTP1
import NIOHTTP2

/// Internal `ChannelInboundHandler` that parses `HTTPClientResponsePart` to `HTTPResponse`.
internal final class HTTP2ClientResponseParser: ChannelInboundHandler {
    /// See `ChannelInboundHandler.InboundIn`.
    typealias InboundIn = HTTPClientResponsePart
    
    /// See `ChannelInboundHandler.OutboundOut`.
    typealias OutboundOut = HTTPResponse
    
    /// Current state.
    private var state: HTTPClientState
    
    /// Creates a new `HTTP2ClientResponseParser`.
    init() {
        self.state = .ready
    }
    
    /// See `ChannelInboundHandler.channelRead(ctx:data:)`.
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        switch unwrapInboundIn(data) {
        case .head(let head):
            switch state {
            case .ready: state = .parsingBody(head, nil)
            case .parsingBody: assert(false, "Unexptected HTTPClientResponsePart.head when body being parsed")
            }
            
        case .body(var body):
            switch state {
            case .ready: assert(false, "Unexpected HTTPClientResponse.body when awaiting request head.")
            case .parsingBody(let head, let existingData):
                let data: Data
                if var existing = existingData {
                    existing += Data(body.readBytes(length: body.readableBytes) ?? [])
                    data = existing
                } else {
                    data = Data(body.readBytes(length: body.readableBytes) ?? [])
                }
                state = .parsingBody(head, data)
            }
            
        case .end(let tailHeaders):
            assert(tailHeaders == nil, "Unexpected tail headers")
            switch state {
            case .ready: assert(false, "Unexpected HTTPClientResponse.end when awaiting request head.")
            case .parsingBody(let head, let data):
                let body: HTTPBody = data.flatMap { .init(data: $0) } ?? .init()
                let res = HTTPResponse(head: head, body: body, channel: ctx.channel)
                ctx.fireChannelRead(wrapOutboundOut(res))
                state = .ready
            }
        }
    }
}

/// Tracks `HTTP2ClientResponseParser`'s state.
private enum HTTPClientState {
    /// Waiting to parse the next response.
    case ready
    
    /// Currently parsing the response's body.
    case parsingBody(HTTPResponseHead, Data?)
}
