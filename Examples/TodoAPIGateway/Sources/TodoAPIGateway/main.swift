import AWSLambda
import NIO
import Logging
import Foundation
import TodoService
import AWSSDKSwiftCore

LoggingSystem.bootstrap(StreamLogHandler.standardError)


let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer { try! group.syncShutdownGracefully() }
let logger = Logger(label: "AWSLambda.TodoAPIGateway")

do {
  logger.info("start runtime")
  let runtime    = try Runtime.createRuntime(eventLoopGroup: group)
  let env        = runtime.environment
  let store      = DynamoTodoStore(
    eventLoopGroup:  group,
    tableName:       "SwiftLambdaTodos",
    accessKeyId:     env.accessKeyId,
    secretAccessKey: env.secretAccessKey,
    sessionToken:    env.sessionToken,
    region:          Region(rawValue: env.region)!)
  let controller = TodoController(store: store)
  
  defer { try! runtime.syncShutdown() }
  
  logger.info("register functions")

  runtime.register(for: "list", handler: APIGateway.handler(controller.listTodos))
  runtime.register(for: "create", handler: APIGateway.handler(controller.createTodo))
  runtime.register(for: "deleteAll", handler: APIGateway.handler(controller.deleteAll))
  runtime.register(for: "getTodo", handler: APIGateway.handler(controller.getTodo))
  runtime.register(for: "deleteTodo", handler: APIGateway.handler(controller.deleteTodo))
  runtime.register(for: "patchTodo", handler: APIGateway.handler(controller.patchTodo))
  
  logger.info("starting runloop")

  try runtime.start().wait()
}
catch {
  logger.error("error: \(String(describing: error))")
}


