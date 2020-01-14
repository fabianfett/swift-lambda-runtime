import LambdaRuntime
import NIO
import Logging
import Foundation

LoggingSystem.bootstrap(StreamLogHandler.standardError)


let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer { try! group.syncShutdownGracefully() }
let logger = Logger(label: "AWSLambda.EventSources")

struct SNSBody: Codable {
  let name: String
  let whatevar: String
}

func handleSNS(event: SNS.Event, ctx: Context) -> EventLoopFuture<Void> {
  do {
    let message = event.records.first!.sns
    let _ = try message.decodeBody(SNSBody.self)
    
    // handle your message
    
    return ctx.eventLoop.makeSucceededFuture(Void())
  }
  catch {
    return ctx.eventLoop.makeFailedFuture(error)
  }
}

func handleSQS(event: SQS.Event, ctx: Context) -> EventLoopFuture<Void> {
  ctx.logger.info("Payload: \(String(describing: event))")
  
  return ctx.eventLoop.makeSucceededFuture(Void())
}

func handleDynamoStream(event: DynamoDB.Event, ctx: Context) -> EventLoopFuture<Void> {
  ctx.logger.info("Payload: \(String(describing: event))")
  
  return ctx.eventLoop.makeSucceededFuture(Void())
}

func handleCloudwatchSchedule(event: Cloudwatch.Event<Cloudwatch.ScheduledEvent>, ctx: Context)
  -> EventLoopFuture<Void>
{
  ctx.logger.info("Payload: \(String(describing: event))")
  
  return ctx.eventLoop.makeSucceededFuture(Void())
}

func handleAPIRequest(req: APIGateway.Request, ctx: Context) -> EventLoopFuture<APIGateway.Response> {
  ctx.logger.info("Payload: \(String(describing: req))")
  
  struct Payload: Encodable {
    let path: String
    let method: String
  }
  
  let payload = Payload(path: req.path, method: req.httpMethod.rawValue)
  let response = try! APIGateway.Response(statusCode: .ok, payload: payload)
  
  return ctx.eventLoop.makeSucceededFuture(response)
}

func handleS3(event: S3.Event, ctx: Context) -> EventLoopFuture<Void> {
  ctx.logger.info("Payload: \(String(describing: event))")
  
  return ctx.eventLoop.makeSucceededFuture(Void())
}

func handleLoadBalancerRequest(req: ALB.TargetGroupRequest, ctx: Context) ->
  EventLoopFuture<ALB.TargetGroupResponse>
{
  ctx.logger.info("Payload: \(String(describing: req))")
  
  struct Payload: Encodable {
    let path: String
    let method: String
  }
  
  let payload = Payload(path: req.path, method: req.httpMethod.rawValue)
  let response = try! ALB.TargetGroupResponse(statusCode: .ok, payload: payload)
  
  return ctx.eventLoop.makeSucceededFuture(response)
}

func printPayload(buffer: NIO.ByteBuffer, ctx: Context) -> EventLoopFuture<ByteBuffer?> {
  let payload = buffer.getString(at: 0, length: buffer.readableBytes)
  ctx.logger.error("Payload: \(String(describing: payload))")

  return ctx.eventLoop.makeSucceededFuture(nil)
}

func printOriginalPayload(_ handler: @escaping (NIO.ByteBuffer, Context) -> EventLoopFuture<ByteBuffer?>)
  -> ((NIO.ByteBuffer, Context) -> EventLoopFuture<ByteBuffer?>)
{
  return { (buffer, ctx) in
    let payload = buffer.getString(at: 0, length: buffer.readableBytes)
    ctx.logger.info("Payload: \(String(describing: payload))")

    return handler(buffer, ctx)
  }
}

do {
  logger.info("start runtime")
  let environment = try Environment()
  let handler: LambdaRuntime.Handler
  
  switch environment.handlerName {
  case "sns":
    handler = printOriginalPayload(LambdaRuntime.codable(handleSNS))
  case "sqs":
    handler = printOriginalPayload(LambdaRuntime.codable(handleSQS))
  case "dynamo":
    handler = printOriginalPayload(LambdaRuntime.codable(handleDynamoStream))
  case "schedule":
    handler = printOriginalPayload(LambdaRuntime.codable(handleCloudwatchSchedule))
  case "api":
    handler = printOriginalPayload(APIGateway.handler(handleAPIRequest))
  case "s3":
    handler = printOriginalPayload(LambdaRuntime.codable(handleS3))
  case "loadbalancer":
    handler = printOriginalPayload(ALB.handler(multiValueHeadersEnabled: true, handleLoadBalancerRequest))
  default:
    handler = printPayload
  }
  
  let runtime = try LambdaRuntime.createRuntime(eventLoopGroup: group, handler: handler)
  defer { try! runtime.syncShutdown() }
  logger.info("starting runloop")

  try runtime.start().wait()
}
catch {
  logger.error("error: \(String(describing: error))")
}


