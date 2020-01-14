import Foundation
import NIO
@_exported import LambdaEvents

extension APIGateway {
  
  public static func handler(
    _ handler: @escaping (APIGateway.Request, Context) -> EventLoopFuture<APIGateway.Response>)
    -> ((NIO.ByteBuffer, Context) -> EventLoopFuture<ByteBuffer?>)
  {
    // reuse as much as possible
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    return { (inputBytes: NIO.ByteBuffer, ctx: Context) -> EventLoopFuture<ByteBuffer?> in
      
      let req: APIGateway.Request
      do {
        req = try decoder.decode(APIGateway.Request.self, from: inputBytes)
      }
      catch {
        return ctx.eventLoop.makeFailedFuture(error)
      }
            
      return handler(req, ctx)
        .flatMapErrorThrowing() { (error) -> APIGateway.Response in
          ctx.logger.error("Unhandled error. Responding with HTTP 500: \(error).")
          return APIGateway.Response(statusCode: .internalServerError)
        }
        .flatMapThrowing { (result: Response) -> NIO.ByteBuffer in
          return try encoder.encodeAsByteBuffer(result, allocator: ByteBufferAllocator())
        }
    }
  }
}
