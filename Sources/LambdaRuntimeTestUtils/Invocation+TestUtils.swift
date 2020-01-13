import Foundation
import NIOHTTP1
@testable import LambdaRuntime

extension Invocation {
  
  public static func forTesting(
    requestId  : String       = UUID().uuidString.lowercased(),
    timeout    : TimeInterval = 1,
    functionArn: String       = "arn:aws:lambda:us-east-1:123456789012:function:custom-runtime",
    traceId    : String       = "Root=1-5bef4de7-ad49b0e87f6ef6c87fc2e700;Parent=9a9197af755a6419;Sampled=1")
    throws -> Invocation
  {
    let deadline = String(Int(Date(timeIntervalSinceNow: timeout).timeIntervalSince1970 * 1000))
    
    let headers = HTTPHeaders([
      ("Lambda-Runtime-Aws-Request-Id"      , requestId),
      ("Lambda-Runtime-Deadline-Ms"         , deadline),
      ("Lambda-Runtime-Invoked-Function-Arn", functionArn),
      ("Lambda-Runtime-Trace-Id"            , traceId),
    ])
    
    return try Invocation(headers: headers)
  }
  
}
