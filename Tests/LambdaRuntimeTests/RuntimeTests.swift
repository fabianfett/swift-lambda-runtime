import Foundation
import XCTest
import NIO
@testable import LambdaRuntime

class RuntimeTests: XCTestCase {
  
  // MARK: - Test Setup -
  
  func testCreateRuntimeHappyPath() {
    
    setenv("AWS_LAMBDA_RUNTIME_API", "localhost", 1)
    setenv("_HANDLER", "haha", 1)
    
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer { XCTAssertNoThrow(try group.syncShutdownGracefully()) }
    
    do {
      let runtime = try Runtime.createRuntime(eventLoopGroup: group) { (_, ctx) in
        return ctx.eventLoop.makeSucceededFuture(nil)
      }
      defer { XCTAssertNoThrow(try runtime.syncShutdown()) }
      XCTAssert(runtime.eventLoopGroup === group)
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testCreateRuntimeMissingLambdaRuntimeAPI() {
    unsetenv("AWS_LAMBDA_RUNTIME_API")

    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer { XCTAssertNoThrow(try group.syncShutdownGracefully()) }
    
    do {
      let runtime = try Runtime.createRuntime(eventLoopGroup: group) { (_, ctx) in
        return ctx.eventLoop.makeSucceededFuture(nil)
      }
      defer { XCTAssertNoThrow(try runtime.syncShutdown()) }
      XCTFail("Did not expect to succeed")
    }
    catch let error as RuntimeError {
      XCTAssertEqual(error, RuntimeError.missingEnvironmentVariable("AWS_LAMBDA_RUNTIME_API"))
    }
    catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  // MARK: - Test Running -
  
//  func testRegisterAFunction() {
//    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//    let client = MockLambdaRuntimeAPI(eventLoopGroup: group)
//    defer {
//      XCTAssertNoThrow(try client.syncShutdown())
//      XCTAssertNoThrow(try group.syncShutdownGracefully())
//    }
//    
//    do {
//      let env = try Environment.forTesting(handler: "lambda.testFunction")
//      
//      let runtime = Runtime(eventLoopGroup: group, client: client, environment: env)
//      let expectation = self.expectation(description: "test function is hit")
//      var hits = 0
//      runtime.register(for: "testFunction") { (req, ctx) -> EventLoopFuture<ByteBuffer> in
//        expectation.fulfill()
//        hits += 1
//        return ctx.eventLoop.makeSucceededFuture(ByteBufferAllocator().buffer(capacity: 0))
//      }
//      
//      _ = runtime.start()
//      
//      self.wait(for: [expectation], timeout: 3)
//      
//      XCTAssertNoThrow(try runtime.syncShutdown())
//      XCTAssertEqual(hits, 1)
//    }
//    catch {
//      XCTFail("Unexpected error: \(error)")
//    }
//  }
  
}

