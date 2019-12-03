import Foundation
import AsyncHTTPClient
import NIO
import NIOHTTP1
import NIOFoundationCompat

struct InvocationError: Codable {
  let errorMessage: String
}

final public class Runtime {
  
  public let eventLoopGroup: EventLoopGroup
  public let runtimeLoop   : EventLoop
  
  /// the name of the function to invoke
  public let handlerName   : String
  public let environment   : Environment

  // MARK: - Private Properties -
  
  private let client: LambdaRuntimeAPI
  
  /// The functions that can be invoked by the runtime by name.
  private var handlers: [String: Handler]
  
  private var shutdownPromise: EventLoopPromise<Void>?
  private var isShutdown: Bool = false
  
  // MARK: - Public Methods -

  /// the runtime shall be initialised with an EventLoopGroup, that is used throughout the lambda
  public static func createRuntime(eventLoopGroup: EventLoopGroup) throws -> Runtime {
    
    let environment = try Environment(ProcessInfo.processInfo.environment)
    
    let client  = RuntimeAPIClient(
      eventLoopGroup: eventLoopGroup,
      lambdaRuntimeAPI: environment.lambdaRuntimeAPI)
    let runtime = Runtime(
      eventLoopGroup: eventLoopGroup,
      client: client,
      environment: environment)
    
    return runtime
  }
  
  init(eventLoopGroup: EventLoopGroup,
       client: LambdaRuntimeAPI,
       environment: Environment)
  {
    
    self.eventLoopGroup = eventLoopGroup
    self.runtimeLoop    = eventLoopGroup.next()
    
    self.client         = client
  
    self.handlerName    = environment.handlerName
    self.handlers       = [:]
    
    
    self.environment    = environment

    // TODO: post init error
    // https://docs.aws.amazon.com/lambda/latest/dg/runtimes-api.html#runtimes-api-initerror
  }
  
  
  public typealias Handler = (NIO.ByteBuffer, Context) -> EventLoopFuture<NIO.ByteBuffer?>
  
  /// Registers a handler function for execution by the runtime. This method is
  /// not thread safe. Therefore it is only safe to invoke this function before
  /// the `start` method is called.
  public func register(for name: String, handler: @escaping Handler) {
    self.runtimeLoop.execute {
      self.handlers[name] = handler
    }
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
          
        setenv("_X_AMZN_TRACE_ID", invocation.traceId, 0)
        
        let context = Context(
          environment: self.environment,
          invocation: invocation,
          eventLoop: self.runtimeLoop)
        
        guard let handler = self.handlers[self.handlerName] else {
          return self.runtimeLoop.makeFailedFuture(RuntimeError.unknownLambdaHandler(self.handlerName))
        }
        
        return handler(byteBuffer, context)
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

