//
//  HTTPRequest.swift
//  NIOH2
//
//  Created by Moritz Sternemann on 26.11.18.
//

import Foundation
import NIO
import NIOHTTP1

/// A HTTP request from a client to a server.
///
///     let httpReq = HTTPRequest(method: .GET, url: "/hello")
///
/// See `HTTP2Client`.
public struct HTTPRequest: HTTPMessage {
    /// Internal storage is an NIO `HTTPRequestHead`.
    internal var head: HTTPRequestHead
    
    // MARK: Properties
    
    /// The HTTP method for this request.
    ///
    ///     httpReq.method = .GET
    ///
    public var method: HTTPMethod {
        get { return head.method }
        set { head.method = newValue }
    }
    
    /// The URL used on this request.
    public var url: URL {
        get { return URL(string: urlString) ?? .root }
        set { urlString = newValue.absoluteString }
    }
    
    /// The unparsed URL string. This is usually set through the `url` property.
    ///
    ///     httpReq.urlString = "/welcome"
    ///
    public var urlString: String {
        get { return head.uri }
        set { head.uri = newValue }
    }
    
    /// The version for this HTTP reqeust.
    public var version: HTTPVersion {
        get { return head.version }
        set { head.version = newValue }
    }
    
    /// The header fields for this HTTP request.
    /// The `"Content-Length"` and `"Transfer-Encoding"` headers will be set automatically.
    /// when the `body` property is mutated.
    public var headers: HTTPHeaders {
        get { return head.headers }
        set { head.headers = newValue }
    }
    
    /// The `HTTPBody`. Updating this property will also update the associated transport headers.
    ///
    ///     httpReq.body = HTTPBody(string: "Hello, world!")
    ///
    /// Also be sure to set this message's `contentType` property to a `MediaType` that correctly
    /// represents the `HTTPBody`.
    public var body: HTTPBody {
        didSet { updateTransportHeaders() }
    }
    
    /// If set, reference to the NIO `Channel` this request came from.
    public var channel: Channel?
    
    /// See `CustomStringConvertible`.
    public var description: String {
        return body.description
    }
    
    /// See `CustomDebugStringConvertible`.
    public var debugDescription: String {
        var desc: [String] = []
        desc.append("\(method) \(url) HTTP/\(version.major).\(version.minor)")
        desc.append(headers.debugDescription)
        desc.append(description)
        return desc.joined(separator: "\n")
    }
    
    // MARK: Init
    
    /// Creates a new `HTTPRequest`.
    ///
    ///     let httpReq = HTTPRequest(method: .GET, url: "/hello")
    ///
    /// - parameters:
    ///     - method: `HTTPMethod` to use. This defaults to `HTTPMethod.GET`.
    ///     - url: A `URLRepresentable` item that represents the request's URL.
    ///            This defaults to `"/"`.
    ///     - version: `HTTPVersion` of this request, should usually be (and defaults to) 2.0.
    ///     - headers: `HTTPHeaders` to include with this request.
    ///                Defaults to empty headers.
    ///                The `"Content-Lenght"` and `"Transfer-Encoding"` headers will be set automatically.
    ///     - body: `HTTPBody` for this request, defaults to an empty body.
    ///             See `LosslessHTTPBodyRepresentable` for more information.
    public init(method: HTTPMethod = .GET,
                url: URLRepresentable = URL.root,
                version: HTTPVersion = .init(major: 2, minor: 0),
                headers: HTTPHeaders = .init(),
                body: LosslessHTTPBodyRepresentable = HTTPBody()) {
        var head = HTTPRequestHead(version: version, method: method, uri: url.convertToURL()?.absoluteString ?? "/")
        head.headers = headers
        self.init(head: head,
                  body: body.convertToHTTPBody(),
                  channel: nil)
        updateTransportHeaders()
    }
    
    /// Internal init that creates a new `HTTPRequest` without sanitizing headers.
    internal init(head: HTTPRequestHead, body: HTTPBody, channel: Channel?) {
        self.head = head
        self.body = body
        self.channel = channel
    }
}
