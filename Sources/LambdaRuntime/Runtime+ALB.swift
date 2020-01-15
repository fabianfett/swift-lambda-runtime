import Foundation
import NIO
import LambdaEvents

extension ALB {
  
  public static func handler(
    multiValueHeadersEnabled: Bool = false,
    _ handler: @escaping (ALB.TargetGroupRequest, Context) -> EventLoopFuture<ALB.TargetGroupResponse>)
    -> ((NIO.ByteBuffer, Context) -> EventLoopFuture<ByteBuffer?>)
  {
    // reuse as much as possible
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    encoder.userInfo[ALB.TargetGroupResponse.MultiValueHeadersEnabledKey] = multiValueHeadersEnabled
    
    return { (inputBytes: NIO.ByteBuffer, ctx: Context) -> EventLoopFuture<ByteBuffer?> in
      
      let req: ALB.TargetGroupRequest
      do {
        req = try decoder.decode(ALB.TargetGroupRequest.self, from: inputBytes)
      }
      catch {
        return ctx.eventLoop.makeFailedFuture(error)
      }
            
      return handler(req, ctx)
        .flatMapErrorThrowing() { (error) -> ALB.TargetGroupResponse in
          ctx.logger.error("Unhandled error. Responding with HTTP 500: \(error).")
          return ALB.TargetGroupResponse(statusCode: .internalServerError)
        }
        .flatMapThrowing { (result: ALB.TargetGroupResponse) -> NIO.ByteBuffer in
          return try encoder.encodeAsByteBuffer(result, allocator: ByteBufferAllocator())
        }
    }
  }
}
