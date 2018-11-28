//
//  HTTPBody.swift
//  NIOH2
//
//  Created by Moritz Sternemann on 26.11.18.
//

import Foundation
import NIO
import NIOHTTP1

public protocol LosslessHTTPBodyRepresentable {
    func convertToHTTPBody() -> HTTPBody
}

extension String: LosslessHTTPBodyRepresentable {
    public func convertToHTTPBody() -> HTTPBody {
        return HTTPBody(string: self)
    }
}

extension Data: LosslessHTTPBodyRepresentable {
    public func convertToHTTPBody() -> HTTPBody {
        return HTTPBody(data: self)
    }
}

extension StaticString: LosslessHTTPBodyRepresentable {
    public func convertToHTTPBody() -> HTTPBody {
        return HTTPBody(staticString: self)
    }
}

extension ByteBuffer: LosslessHTTPBodyRepresentable {
    public func convertToHTTPBody() -> HTTPBody {
        return HTTPBody(buffer: self)
    }
}

public struct HTTPBody: LosslessHTTPBodyRepresentable, CustomStringConvertible {
    public static let empty: HTTPBody = .init()
    
    public var data: Data? {
        return storage.data
    }
    
    public var count: Int? {
        return storage.count
    }
    
    public var description: String {
        switch storage {
        case .none: return "<no body>"
        case .buffer(let buffer): return buffer.getString(at: 0, length: buffer.readableBytes) ?? "n/a"
        case .data(let data): return String(data: data, encoding: .ascii) ?? "n/a"
        case .dispatchData(let dispatchData): return String(data: Data(dispatchData), encoding: .ascii) ?? "n/a"
        case .staticString(let staticString): return staticString.description
        case .string(let string): return string
        }
    }
    
    var storage: HTTPBodyStorage
    
    public init() {
        self.storage = .none
    }
    
    public init(data: Data) {
        self.storage = .data(data)
    }
    
    public init(dispatchData: DispatchData) {
        self.storage = .dispatchData(dispatchData)
    }
    
    public init(staticString: StaticString) {
        self.storage = .staticString(staticString)
    }
    
    public init(string: String) {
        self.storage = .string(string)
    }
    
    public init(buffer: ByteBuffer) {
        self.storage = .buffer(buffer)
    }
    
    internal init(storage: HTTPBodyStorage) {
        self.storage = storage
    }
    
    public func convertToHTTPBody() -> HTTPBody {
        return self
    }
}

internal enum HTTPBodyStorage {
    case none
    case buffer(ByteBuffer)
    case data(Data)
    case staticString(StaticString)
    case dispatchData(DispatchData)
    case string(String)
    
    var count: Int? {
        switch self {
        case .data(let data): return data.count
        case .dispatchData(let data): return data.count
        case .staticString(let staticString): return staticString.utf8CodeUnitCount
        case .string(let string): return string.utf8.count
        case .buffer(let buffer): return buffer.readableBytes
        case .none: return 0
        }
    }
    
    var data: Data? {
        switch self {
        case .buffer(let buffer): return Data(buffer.getBytes(at: 0, length: buffer.readableBytes) ?? [])
        case .data(let data): return data
        case .dispatchData(let dispatch): return Data(dispatch)
        case .staticString(let staticString): return Data(bytes: staticString.utf8Start, count: staticString.utf8CodeUnitCount)
        case .string(let string): return Data(string.utf8)
        case .none: return nil
        }
    }
}
