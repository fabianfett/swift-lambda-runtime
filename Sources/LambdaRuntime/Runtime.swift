import Foundation
import AsyncHTTPClient
import NIO
import NIOHTTP1
import NIOFoundationCompat

public struct InvocationError: Codable {
  let errorMessage: String
}

final public class Runtime {
  
  public typealias Handler = (NIO.ByteBuffer, Context) -> EventLoopFuture<NIO.ByteBuffer?>
  
  public let eventLoopGroup: EventLoopGroup
  public let runtimeLoop   : EventLoop
  
  public let environment   : Environment
  public let handler       : Handler

  // MARK: - Private Properties -
  
  private let client: LambdaRuntimeAPI
  
  private var shutdownPromise: EventLoopPromise<Void>?
  private var isShutdown: Bool = false
  
  // MARK: - Public Methods -

  /// the runtime shall be initialised with an EventLoopGroup, that is used throughout the lambda
  public static func createRuntime(eventLoopGroup: EventLoopGroup, environment: Environment? = nil, handler: @escaping Handler)
    throws -> Runtime
  {
    let env = try environment ?? Environment()
    
    let client  = RuntimeAPIClient(
      eventLoopGroup: eventLoopGroup,
      lambdaRuntimeAPI: env.lambdaRuntimeAPI)
    let runtime = Runtime(
      eventLoopGroup: eventLoopGroup,
      client: client,
      environment: env,
      handler: handler)
    
    return runtime
  }
  
  init(eventLoopGroup: EventLoopGroup,
       client: LambdaRuntimeAPI,
       environment: Environment,
       handler: @escaping Handler)
  {
    self.eventLoopGroup = eventLoopGroup
    self.runtimeLoop    = eventLoopGroup.next()
    
    self.client         = client
    self.environment    = environment
    self.handler        = handler

    // TODO: post init error
    // https://docs.aws.amazon.com/lambda/latest/dg/runtimes-api.html#runtimes-api-initerror
  }
  
  // MARK: Runtime loop
  
  public func start() -> EventLoopFuture<Void> {
    precondition(self.shutdownPromise == nil)
    
    self.shutdownPromise = self.runtimeLoop.makePromise(of: Void.self)
    self.runtimeLoop.execute {
      self.runner()
    }
    
    return self.shutdownPromise!.futureResult
  }
  
  public func syncShutdown() throws {
    
    self.runtimeLoop.execute {
      self.isShutdown = true
    }
    
    try self.shutdownPromise?.futureResult.wait()
    try self.client.syncShutdown()
  }
  
  // MARK: - Private Methods -
  
  private func runner() {
    precondition(self.runtimeLoop.inEventLoop)
      
    _ = self.client.getNextInvocation()
      .hop(to: self.runtimeLoop)
      .flatMap { (invocation, byteBuffer) -> EventLoopFuture<Void> in
        
        // TBD: Does it make sense to also set this env variable?
        setenv("_X_AMZN_TRACE_ID", invocation.traceId, 0)
        
        let context = Context(
          environment: self.environment,
          invocation: invocation,
          eventLoop: self.runtimeLoop)
                
        return self.handler(byteBuffer, context)
          .flatMap { (byteBuffer) -> EventLoopFuture<Void> in
            return self.client.postInvocationResponse(for: context.requestId, httpBody: byteBuffer)
          }
          .flatMapError { (error) -> EventLoopFuture<Void> in
            return self.client.postInvocationError(for: context.requestId, error: error)
          }
          .flatMapErrorThrowing { (error) in
            context.logger.error("Could not post lambda result to runtime. error: \(error)")
          }
      }
      .hop(to: self.runtimeLoop)
      .whenComplete() { (_) in
        precondition(self.runtimeLoop.inEventLoop)
        
        if !self.isShutdown {
          self.runner()
        }
        else {
          self.shutdownPromise?.succeed(Void())
        }
      }
  }
}
