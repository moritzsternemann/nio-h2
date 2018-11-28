//
//  HTTP2Client.swift
//  NIOH2
//
//  Created by Moritz Sternemann on 26.11.18.
//

import Foundation
import NIO
import NIOOpenSSL
import NIOHTTP1
import NIOHTTP2

let url = URL(string: "https://strnmn.me")!

/// Connects to remote HTTP/2 servers allowing you to send HTTP/2 requests and receive responses.
public final class HTTP2Client {
    // MARK: Static
    
    /// Creates a new `HTTP2Client`.
    ///
    ///     let httpRes = HTTP2Client.connect(hostname: "strnmn.me", on: ...).map(to: HTTPResponse.self) { client in
    ///         return client.send(...)
    ///     }
    ///
    /// - parameters:
    ///     - hostname: Remote server's hostname.
    ///     - port: Remote server's port, defaults to 443.
    ///     - connectTimeout: The timeout that will apply to the connection attempt.
    ///     - group: `EventLoopGroup` to perform async work on.
    ///     - onError: Optional closure, which fires when a networking error is caught.
    /// - returns: A `EventLoopFuture` containing the connected `HTTP2Client`.
    public static func connect(
        hostname: String,
        port: Int? = nil,
        connectTimeout: TimeAmount = TimeAmount.seconds(10),
        on group: EventLoopGroup,
        onError: @escaping (Error) -> Void = { _ in }
    ) -> EventLoopFuture<HTTP2Client> {
        let queueHandler = QueueHandler<HTTPResponse, HTTPRequest>(on: group) { error in
            print("ERROR: \(error)")
            onError(error)
        }
        
        let tlsConfig = TLSConfiguration.forClient(applicationProtocols: ["h2"])
        let sslContext = try! SSLContext(configuration: tlsConfig)
        
        let bootstrap = ClientBootstrap(group: group)
            .connectTimeout(connectTimeout)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelInitializer { channel in
                let myEventLoop = channel.eventLoop
                let sslHandler = try! OpenSSLClientHandler(context: sslContext, serverHostname: hostname)
                let http2Multiplexer = HTTP2StreamMultiplexer { (channel, streamID) -> EventLoopFuture<Void> in
                    return myEventLoop.newSucceededFuture(result: ())
                }
                
                let handlers: [ChannelHandler] = [
                    sslHandler,
                    HTTP2Parser(mode: .client),
                    http2Multiplexer,
                    HTTP2StreamChannelCreator(multiplexer: http2Multiplexer, handlers: [
                        HTTP2ClientRequestSerializer(hostname: hostname),
                        HTTP2ClientResponseParser(),
                        queueHandler
                    ])
                ]
                
                return channel.pipeline.addHandlers(handlers, first: false)
        }
        
        return bootstrap.connect(host: hostname, port: port ?? 443).map(to: HTTP2Client.self) { channel in
            return .init(handler: queueHandler, channel: channel)
        }
    }
    
    // MARK: Properties
    
    /// Private `ChannelInboundHandler` that handles requests.
    private let handler: QueueHandler<HTTPResponse, HTTPRequest>
    
    /// NIO `Channel` powering this client.
    public let channel: Channel
    
    /// A `EventLoopFuture` that will complete when this `HTTP2Client` closes.
    public var onClose: EventLoopFuture<Void> {
        return channel.closeFuture
    }
    
    /// Private init for creating a new `HTTP2Client`. Use the `connect` method.
    private init(handler: QueueHandler<HTTPResponse, HTTPRequest>, channel: Channel) {
        self.handler = handler
        self.channel = channel
    }
    
    // MARK: Methods
    
    /// Send an `HTTPRequest` to the connected remote server.
    ///
    ///     let httpRes = HTTP2Client.connect(hostname: "strnmn.me", on: ...).map(to: HTTPResponse.self) { client in
    ///         return client.send(...)
    ///     }
    ///
    /// - parameters:
    ///     - request: `HTTPRequest` to send to the remote server.
    /// - returns: A `EventLoopFuture` `HTTPResponse` containing the server's response.
    public func send(_ request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        var res: HTTPResponse?
        return handler.enqueue([request]) { _res in
            res = _res
            return true
        }.map(to: HTTPResponse.self) {
            return res!
        }
    }
    
    /// Closes this `HTTP2Client`'s connection to the remote server.penis
    public func close() -> EventLoopFuture<Void> {
        return channel.close(mode: .all)
    }
}
