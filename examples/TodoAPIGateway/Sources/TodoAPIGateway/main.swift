import LambdaRuntime
import NIO
import Logging
import Foundation
import TodoService
import AWSSDKSwiftCore

LoggingSystem.bootstrap(StreamLogHandler.standardError)


let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer { try! group.syncShutdownGracefully() }
let logger = Logger(label: "Lambda.TodoAPIGateway")

do {
  logger.info("start runtime")
  
  let env        = try Environment()
  let store      = DynamoTodoStore(
    eventLoopGroup:  group,
    tableName:       "SwiftLambdaTodos",
    accessKeyId:     env.accessKeyId,
    secretAccessKey: env.secretAccessKey,
    sessionToken:    env.sessionToken,
    region:          Region(rawValue: env.region)!)
  let controller = TodoController(store: store)
  
  logger.info("register function")

  let handler: LambdaRuntime.Handler
  switch env.handlerName {
  case "list":
    handler = APIGateway.handler(controller.listTodos)
  case "create":
    handler = APIGateway.handler(controller.createTodo)
  case "deleteAll":
    handler = APIGateway.handler(controller.deleteAll)
  case "getTodo":
    handler = APIGateway.handler(controller.getTodo)
  case "deleteTodo":
    handler = APIGateway.handler(controller.deleteTodo)
  case "patchTodo":
    handler = APIGateway.handler(controller.patchTodo)
  default:
    fatalError("Unexpected handler")
  }
  
  logger.info("starting runloop")

  let runtime    = try LambdaRuntime.createRuntime(eventLoopGroup: group, environment: env, handler: handler)
  defer { try! runtime.syncShutdown() }
  try runtime.start().wait()
}
catch {
  logger.error("error: \(String(describing: error))")
}


