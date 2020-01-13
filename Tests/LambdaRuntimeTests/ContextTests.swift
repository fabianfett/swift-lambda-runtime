import Foundation
import XCTest
import NIO
import LambdaRuntimeTestUtils
@testable import LambdaRuntime

class ContextTests: XCTestCase {
  
  public func testDeadline() {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer {
        XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
    }
    
    do {
      let timeout: TimeInterval = 3
      let context = try Context(
        environment: .forTesting(),
        invocation: .forTesting(timeout: timeout),
        eventLoop: eventLoopGroup.next())
      
      let remaining = context.getRemainingTime()
      
      XCTAssert(timeout > remaining && remaining > timeout * 0.99, "Expected the remaining time to be within 99%")
    }
    catch {
      XCTFail("unexpected error: \(error)")
    }
  }

}
