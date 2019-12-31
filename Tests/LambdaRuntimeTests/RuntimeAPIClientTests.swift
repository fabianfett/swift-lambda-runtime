import Foundation
import XCTest
import NIO
import NIOHTTP1
import NIOTestUtils
@testable import LambdaRuntime

class RuntimeAPIClientTests: XCTestCase {
  
  struct InvocationBody: Codable {
    let test: String
  }
  
  func testGetNextInvocationHappyPathTest() {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let web = NIOHTTP1TestServer(group: group)
    let client = RuntimeAPIClient(eventLoopGroup: group, lambdaRuntimeAPI: "localhost:\(web.serverPort)")
    
    defer {
      XCTAssertNoThrow(try client.syncShutdown())
      XCTAssertNoThrow(try web.stop())
      XCTAssertNoThrow(try group.syncShutdownGracefully())
    }
    
    let result = client.getNextInvocation()
    
    XCTAssertNoThrow(try XCTAssertEqual(
      web.readInbound(),
      HTTPServerRequestPart.head(.init(version: .init(major: 1, minor: 1), method: .GET, uri: "/2018-06-01/runtime/invocation/next", headers:
        HTTPHeaders([("Host", "localhost"), ("Connection", "close"), ("Content-Length", "0")])))))
    XCTAssertNoThrow(try XCTAssertEqual(
      web.readInbound(),
      HTTPServerRequestPart.end(nil)))
    
    let now = UInt(Date().timeIntervalSinceNow * 1000 + 1000)
    
    XCTAssertNoThrow(try web.writeOutbound(
      .head(.init(version: .init(major: 1, minor: 1), status: .ok, headers: HTTPHeaders([
        ("Lambda-Runtime-Aws-Request-Id", UUID().uuidString),
        ("Lambda-Runtime-Deadline-Ms", "\(now)"),
        ("Lambda-Runtime-Invoked-Function-Arn", "fancy:arn"),
        ("Lambda-Runtime-Trace-Id", "aTraceId"),
        ("Lambda-Runtime-Client-Context", "someContext"),
        ("Lambda-Runtime-Cognito-Identity", "someIdentity"),
      ])))))
    
    XCTAssertNoThrow(try web.writeOutbound(
      .body(.byteBuffer(try JSONEncoder().encodeAsByteBuffer(InvocationBody(test: "abc"), allocator: ByteBufferAllocator())))))
    XCTAssertNoThrow(try web.writeOutbound(.end(nil)))
    
    XCTAssertNoThrow(try result.wait())
    
  }
  
  struct InvocationResponse: Codable {
    let msg: String
  }
  
  func testPostInvocationResponseHappyPath() {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let web = NIOHTTP1TestServer(group: group)
    let client = RuntimeAPIClient(eventLoopGroup: group, lambdaRuntimeAPI: "localhost:\(web.serverPort)")
    defer {
      XCTAssertNoThrow(try web.stop())
      XCTAssertNoThrow(try client.syncShutdown())
      XCTAssertNoThrow(try group.syncShutdownGracefully())
    }

    do {
      let invocationId = "abc"
      let resp   = InvocationResponse(msg: "hello world!")
      let body   = try JSONEncoder().encodeAsByteBuffer(resp, allocator: ByteBufferAllocator())
      let result = client.postInvocationResponse(for: invocationId, httpBody: body)
      
      XCTAssertNoThrow(try XCTAssertEqual(
        web.readInbound(),
        HTTPServerRequestPart.head(.init(version: .init(major: 1, minor: 1), method: .POST,
          uri: "/2018-06-01/runtime/invocation/\(invocationId)/response",
          headers: HTTPHeaders([("Host", "localhost"), ("Connection", "close"), ("Content-Length", "\(body.readableBytes)")])))))
      XCTAssertNoThrow(try XCTAssertEqual(
        web.readInbound(),
        HTTPServerRequestPart.body(body)))
      XCTAssertNoThrow(try XCTAssertEqual(
        web.readInbound(),
        HTTPServerRequestPart.end(nil)))

      XCTAssertNoThrow(try web.writeOutbound(
        .head(.init(version: .init(major: 1, minor: 1), status: .ok, headers: HTTPHeaders([])))))
      XCTAssertNoThrow(try web.writeOutbound(.end(nil)))
      
      XCTAssertNoThrow(try result.wait())

    }
    catch {
      XCTFail("unexpected error: \(error)")
    }
  }
  
  enum TestError: Error {
    case unknown
  }
  
  func testPostInvocationErrorHappyPath() {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let web = NIOHTTP1TestServer(group: group)
    let client = RuntimeAPIClient(eventLoopGroup: group, lambdaRuntimeAPI: "localhost:\(web.serverPort)")
    defer {
      XCTAssertNoThrow(try web.stop())
      XCTAssertNoThrow(try client.syncShutdown())
      XCTAssertNoThrow(try group.syncShutdownGracefully())
    }

    do {
      let invocationId = "abc"
      let error  = TestError.unknown
      let result = client.postInvocationError(for: invocationId, error: error)
      
      let respError = InvocationError(errorMessage: String(describing: error))
      let body   = try JSONEncoder().encodeAsByteBuffer(respError, allocator: ByteBufferAllocator())
      
      XCTAssertNoThrow(try XCTAssertEqual(
        web.readInbound(),
        HTTPServerRequestPart.head(.init(version: .init(major: 1, minor: 1), method: .POST,
          uri: "/2018-06-01/runtime/invocation/\(invocationId)/error",
          headers: HTTPHeaders([("Host", "localhost"), ("Connection", "close"), ("Content-Length", "\(body.readableBytes)")])))))
      XCTAssertNoThrow(try XCTAssertEqual(
        web.readInbound(),
        HTTPServerRequestPart.body(body)))
      XCTAssertNoThrow(try XCTAssertEqual(
        web.readInbound(),
        HTTPServerRequestPart.end(nil)))

      XCTAssertNoThrow(try web.writeOutbound(
        .head(.init(version: .init(major: 1, minor: 1), status: .ok, headers: HTTPHeaders([])))))
      XCTAssertNoThrow(try web.writeOutbound(.end(nil)))
      
      XCTAssertNoThrow(try result.wait())

    }
    catch {
      XCTFail("unexpected error: \(error)")
    }
  }
}
