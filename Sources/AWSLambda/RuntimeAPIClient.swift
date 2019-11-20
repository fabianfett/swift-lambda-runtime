import NIO
import NIOHTTP1
import NIOFoundationCompat
import AsyncHTTPClient
import Foundation

public struct Invocation {
  public let requestId         : String
  public let deadlineDate      : Date
  public let invokedFunctionArn: String
  public let traceId           : String
  public let clientContext     : String?
  public let cognitoIdentity   : String?
  
  init(headers: HTTPHeaders) throws {
    
    guard let requestId = headers["Lambda-Runtime-Aws-Request-Id"].first else {
      throw RuntimeError.invocationMissingHeader("Lambda-Runtime-Aws-Request-Id")
    }
    
    guard let unixTimeMilliseconds = headers["Lambda-Runtime-Deadline-Ms"].first,
          let timeInterval         = TimeInterval(unixTimeMilliseconds)
      else
    {
      throw RuntimeError.invocationMissingHeader("Lambda-Runtime-Deadline-Ms")
    }
    
    guard let invokedFunctionArn = headers["Lambda-Runtime-Invoked-Function-Arn"].first else {
      throw RuntimeError.invocationMissingHeader("Lambda-Runtime-Invoked-Function-Arn")
    }
    
    guard let traceId = headers["Lambda-Runtime-Trace-Id"].first else {
      throw RuntimeError.invocationMissingHeader("Lambda-Runtime-Trace-Id")
    }
    
    self.requestId          = requestId
    self.deadlineDate       = Date(timeIntervalSince1970: timeInterval / 1000)
    self.invokedFunctionArn = invokedFunctionArn
    self.traceId            = traceId
    self.clientContext      = headers["Lambda-Runtime-Client-Context"].first
    self.cognitoIdentity    = headers["Lambda-Runtime-Cognito-Identity"].first
  }

}

/// This protocol defines the Lambda Runtime API as defined here.
/// The sole purpose of this protocol is to define stubs to make
/// testing easier.
/// Therefore use is internal only.
/// https://docs.aws.amazon.com/en_pv/lambda/latest/dg/runtimes-api.html
protocol LambdaRuntimeAPI {
  
  func getNextInvocation() -> EventLoopFuture<(Invocation, NIO.ByteBuffer)>
  func postInvocationResponse(for requestId: String, httpBody: NIO.ByteBuffer) -> EventLoopFuture<Void>
  func postInvocationError(for requestId: String, error: Error) -> EventLoopFuture<Void>
  
  func syncShutdown() throws
  
}

final class RuntimeAPIClient {
  
  let httpClient      : HTTPClient
  
  /// the local domain to call, to get the next task/invocation
  /// as defined here: https://docs.aws.amazon.com/en_pv/lambda/latest/dg/runtimes-api.html#runtimes-api-next
  let lambdaRuntimeAPI: String
  
  init(eventLoopGroup: EventLoopGroup, lambdaRuntimeAPI: String) {
    
    self.httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
    self.lambdaRuntimeAPI = lambdaRuntimeAPI
    
  }
}

extension RuntimeAPIClient: LambdaRuntimeAPI {
  
  func getNextInvocation() -> EventLoopFuture<(Invocation, NIO.ByteBuffer)> {
    return self.httpClient
      .get(url: "http://\(lambdaRuntimeAPI)/2018-06-01/runtime/invocation/next")
      .flatMapErrorThrowing { (error) -> HTTPClient.Response in
        throw RuntimeError.endpointError(error.localizedDescription)
      }
      .flatMapThrowing { (response) -> (Invocation, NIO.ByteBuffer) in
        guard let data = response.body else {
          throw RuntimeError.invocationMissingData
        }
          
        return (try Invocation(headers: response.headers), data)
      }
  }

  func postInvocationResponse(for requestId: String, httpBody: NIO.ByteBuffer) -> EventLoopFuture<Void> {
    let url = "http://\(lambdaRuntimeAPI)/2018-06-01/runtime/invocation/\(requestId)/response"
    return self.httpClient.post(url: url, body: .byteBuffer(httpBody))
      .map { (_) -> Void in }
  }

  func postInvocationError(for requestId: String, error: Error) -> EventLoopFuture<Void> {
    let errorMessage = String(describing: error)
    let invocationError = InvocationError(errorMessage: errorMessage)
    let jsonEncoder = JSONEncoder()
    let httpBody = try! jsonEncoder.encodeAsByteBuffer(invocationError, allocator: ByteBufferAllocator())
    
    let url = "http://\(lambdaRuntimeAPI)/2018-06-01/runtime/invocation/\(requestId)/error"
    
    return self.httpClient.post(url: url, body: .byteBuffer(httpBody))
      .map { (_) -> Void in }
  }

  func syncShutdown() throws {
    try self.httpClient.syncShutdown()
  }
  
}
