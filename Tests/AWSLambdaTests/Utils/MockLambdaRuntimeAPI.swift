//
//  File.swift
//  
//
//  Created by Fabian Fett on 11.11.19.
//

import Foundation
import NIO
@testable import AWSLambda

class MockLambdaRuntimeAPI {
  
  let eventLoopGroup : EventLoopGroup
  let runLoop        : EventLoop
  let maxInvocations : Int
  var invocationCount: Int = 0
  
  private var isShutdown = false

  init(eventLoopGroup: EventLoopGroup, maxInvocations: Int) {
    self.eventLoopGroup = eventLoopGroup
    self.runLoop        = eventLoopGroup.next()
    self.maxInvocations = maxInvocations
  }
}

struct TestRequest: Codable {
  let name: String
}

struct TestResponse: Codable {
  let greeting: String
}

extension MockLambdaRuntimeAPI: LambdaRuntimeAPI {
  
  func getNextInvocation() -> EventLoopFuture<(Invocation, ByteBuffer)> {
    do {
      let invocation = try Invocation.forTesting()
      let payload = try JSONEncoder().encodeAsByteBuffer(
        TestRequest(name: "world"),
        allocator: ByteBufferAllocator())
      return self.runLoop.makeSucceededFuture((invocation, payload))
    }
    catch {
      return self.runLoop.makeFailedFuture(error)
    }
  }
  
  func postInvocationResponse(for requestId: String, httpBody: ByteBuffer) -> EventLoopFuture<Void> {
    return self.runLoop.makeSucceededFuture(Void())
  }
  
  func postInvocationError(for requestId: String, error: Error) -> EventLoopFuture<Void> {
    return self.runLoop.makeSucceededFuture(Void())
  }
  
  func syncShutdown() throws {
    self.runLoop.execute {
      self.isShutdown = true
    }
  }
  
}

extension Invocation {
  
  
  
}
