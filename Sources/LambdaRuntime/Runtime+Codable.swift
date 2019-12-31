import Foundation
import NIO
import NIOFoundationCompat

extension LambdaRuntime {
    
  /// wrapper to use for the register function that wraps the encoding and decoding
  public static func codable<Event: Decodable, Result: Encodable>(
    _ handler: @escaping (Event, Context) -> EventLoopFuture<Result>)
    -> ((NIO.ByteBuffer, Context) -> EventLoopFuture<ByteBuffer?>)
  {
    return { (inputBytes: NIO.ByteBuffer, ctx: Context) -> EventLoopFuture<ByteBuffer?> in
      let input: Event
      do {
        input = try JSONDecoder().decode(Event.self, from: inputBytes)
      }
      catch {
        return ctx.eventLoop.makeFailedFuture(error)
      }
      
      return handler(input, ctx)
        .flatMapThrowing { (encodable) -> NIO.ByteBuffer in
          return try JSONEncoder().encodeAsByteBuffer(encodable, allocator: ByteBufferAllocator())
        }
    }
  }
  
  public static func codable<Event: Decodable>(
    _ handler: @escaping (Event, Context) -> EventLoopFuture<Void>)
    -> ((NIO.ByteBuffer, Context) -> EventLoopFuture<ByteBuffer?>)
  {
    return { (inputBytes: NIO.ByteBuffer, ctx: Context) -> EventLoopFuture<ByteBuffer?> in
      let input: Event
      do {
        input = try JSONDecoder().decode(Event.self, from: inputBytes)
      }
      catch {
        return ctx.eventLoop.makeFailedFuture(error)
      }
      
      return handler(input, ctx).map { return nil }
    }
  }
}
