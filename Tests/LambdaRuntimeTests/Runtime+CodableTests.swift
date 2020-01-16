import Foundation
import XCTest
import NIO
import NIOHTTP1
@testable import LambdaRuntime
import LambdaRuntimeTestUtils

class RuntimeCodableTests: XCTestCase {
    
  override func setUp() {

  }
  
  override func tearDown() {

  }
  
  struct TestRequest: Codable {
    let name: String
  }
  
  struct TestResponse: Codable, Equatable {
    let greeting: String
  }
  
  func testCodableHandlerWithResultSuccess() {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer {
        XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
    }
    let handler = Runtime.codable { (req: TestRequest, ctx) -> EventLoopFuture<TestResponse> in
      return ctx.eventLoop.makeSucceededFuture(TestResponse(greeting: "Hello \(req.name)!"))
    }
    
    do {
      let inputBytes = try JSONEncoder().encodeAsByteBuffer(TestRequest(name: "world"), allocator: ByteBufferAllocator())
      let ctx = try Context(environment: .forTesting(), invocation: .forTesting(), eventLoop: eventLoopGroup.next())
      
      let response = try handler(inputBytes, ctx).flatMapThrowing { (bytes) -> TestResponse in
        return try JSONDecoder().decode(TestResponse.self, from: bytes!)
      }.wait()
      
      XCTAssertEqual(response, TestResponse(greeting: "Hello world!"))
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func testCodableHandlerWithResultInvalidInput() {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer {
        XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
    }
    let handler = Runtime.codable { (req: TestRequest, ctx) -> EventLoopFuture<TestResponse> in
      return ctx.eventLoop.makeSucceededFuture(TestResponse(greeting: "Hello \(req.name)!"))
    }
    
    do {
      var inputBytes = try JSONEncoder().encodeAsByteBuffer(TestRequest(name: "world"), allocator: ByteBufferAllocator())
      inputBytes.setString("asd", at: 0) // destroy the json
      let ctx = try Context(environment: .forTesting(), invocation: .forTesting(), eventLoop: eventLoopGroup.next())
      
      _ = try handler(inputBytes, ctx).flatMapThrowing { (outputBytes) -> TestResponse in
        XCTFail("The function should not be invoked.")
        return try JSONDecoder().decode(TestResponse.self, from: outputBytes!)
      }.wait()
      
      XCTFail("Did not expect to succeed.")
    }
    catch DecodingError.dataCorrupted(_) {
      // this is our expected case
    }
    catch {
      XCTFail("Expected to have an data corrupted error")
    }
  }
  
  func testCodableHandlerWithoutResultSuccess() {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer {
        XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
    }
    let handler = Runtime.codable { (req: TestRequest, ctx) -> EventLoopFuture<Void> in
      return ctx.eventLoop.makeSucceededFuture(Void())
    }
    
    do {
      let inputBytes = try JSONEncoder().encodeAsByteBuffer(TestRequest(name: "world"), allocator: ByteBufferAllocator())
      let ctx = try Context(environment: .forTesting(), invocation: .forTesting(), eventLoop: eventLoopGroup.next())
      
      _ = try handler(inputBytes, ctx).wait()
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func testCodableHandlerWithoutResultInvalidInput() {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer {
        XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
    }
    let handler = Runtime.codable { (req: TestRequest, ctx) -> EventLoopFuture<Void> in
      return ctx.eventLoop.makeSucceededFuture(Void())
    }
    
    do {
      var inputBytes = try JSONEncoder().encodeAsByteBuffer(TestRequest(name: "world"), allocator: ByteBufferAllocator())
      inputBytes.setString("asd", at: 0) // destroy the json
      let ctx = try Context(environment: .forTesting(), invocation: .forTesting(), eventLoop: eventLoopGroup.next())
      
      _ = try handler(inputBytes, ctx).wait()
      
      XCTFail("Did not expect to succeed.")
    }
    catch DecodingError.dataCorrupted(_) {
      // this is our expected case
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func testCodableHandlerWithoutResultFailure() {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer {
        XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
    }
    let handler = Runtime.codable { (req: TestRequest, ctx) -> EventLoopFuture<Void> in
      return ctx.eventLoop.makeFailedFuture(RuntimeError.unknown)
    }
    
    do {
      let inputBytes = try JSONEncoder().encodeAsByteBuffer(TestRequest(name: "world"), allocator: ByteBufferAllocator())
      let ctx = try Context(environment: .forTesting(), invocation: .forTesting(), eventLoop: eventLoopGroup.next())
      
      _ = try handler(inputBytes, ctx).wait()
      
      XCTFail("Did not expect to reach this point")
    }
    catch RuntimeError.unknown {
      // expected case
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
