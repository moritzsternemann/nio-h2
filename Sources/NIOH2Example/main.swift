//
//  main.swift
//  NIOH2Example
//
//  Created by Moritz Sternemann on 26.11.18.
//

import Foundation
import NIO
import NIOH2

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
var verbose = false
var args = CommandLine.arguments.dropFirst(0)

func usage() {
    print("Usage: nio-h2-example [-v] https://host:port/path")
    print()
    print("OPTIONS:")
    print("    -v: verbose operation (print response code, headers, etc.)")
}

if case .some(let arg) = args.dropFirst().first, arg.starts(with: "-") {
    switch arg {
    case "-v":
        verbose = true
        args = args.dropFirst()
    default:
        usage()
        exit(1)
    }
}

guard let url = args.dropFirst().first.flatMap(URL.init(string:)) else {
    print("url")
    usage()
    exit(1)
}
guard let host = url.host else {
    usage()
    exit(1)
}
guard url.scheme == "https" else {
    print("ERROR: URL '\(url)' is not https but that's required.")
    exit(1)
}

let port = url.port ?? 443


defer {
    try! group.syncShutdownGracefully()
}

do {
    let client = try HTTP2Client.connect(hostname: host, on: group).wait()
    if verbose {
        print("* Connected to \(host) (\(client.channel.remoteAddress!))")
    }
    
    let request = HTTPRequest()
    let response = try client.send(request).wait()
    if verbose {
        print(response.debugDescription)
    } else {
        print(response.description)
    }
} catch {
    print("ERROR: \(error)")
}
