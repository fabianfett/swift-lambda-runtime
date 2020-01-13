import Foundation
import NIO
import NIOHTTP1
import Logging

/// TBD: What shall the context be? A struct? A class?
public class Context {
  
  public let environment : Environment
  public let invocation  : Invocation
  
  public let traceId     : String
  public let requestId   : String
  
  public let logger      : Logger
  public let eventLoop   : EventLoop
  public let deadlineDate: Date

  public init(environment: Environment, invocation: Invocation, eventLoop: EventLoop) {
    
    var logger        = Logger(label: "AWSLambda.request-logger")
    logger[metadataKey: "RequestId"] = .string(invocation.requestId)
    logger[metadataKey: "TraceId"  ] = .string(invocation.traceId)
    
    self.environment  = environment
    self.invocation   = invocation
    self.eventLoop    = eventLoop
    self.logger       = logger
    self.requestId    = invocation.requestId
    self.traceId      = invocation.traceId
    self.deadlineDate = invocation.deadlineDate
  }

  public func getRemainingTime() -> TimeInterval {
    return deadlineDate.timeIntervalSinceNow
  }
}
