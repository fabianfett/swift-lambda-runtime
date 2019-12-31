import Foundation
import NIO
import NIOHTTP1
import TodoService
import LambdaRuntime

class TodoController {
  
  let store          : TodoStore
  
  static let sharedHeader = HTTPHeaders([
    ("Access-Control-Allow-Methods", "OPTIONS,GET,POST,DELETE"),
    ("Access-Control-Allow-Origin" , "*"),
    ("Access-Control-Allow-Headers", "Content-Type"),
    ("Server", "Swift on AWS Lambda"),
  ])
  
  init(store: TodoStore) {
    self.store = store
  }
  
  func listTodos(request: APIGateway.Request, context: Context) -> EventLoopFuture<APIGateway.Response> {
    return self.store.getTodos()
      .flatMapThrowing { (items) -> APIGateway.Response in
        return try APIGateway.Response(
          statusCode: .ok,
          headers: TodoController.sharedHeader,
          payload: items,
          encoder: self.createResponseEncoder(request))
      }
  }
  
  struct NewTodo: Decodable {
    let title: String
    let order: Int?
    let completed: Bool?
  }
  
  func createTodo(request: APIGateway.Request, context: Context) -> EventLoopFuture<APIGateway.Response> {
    let newTodo: TodoItem
    do {
      let payload: NewTodo = try request.payload()
      newTodo = TodoItem(
        id: UUID().uuidString.lowercased(),
        order: payload.order,
        title: payload.title,
        completed: payload.completed ?? false)
    }
    catch {
      return context.eventLoop.makeFailedFuture(error)
    }
    
    return self.store.createTodo(newTodo)
      .flatMapThrowing { (todo) -> APIGateway.Response in
        return try APIGateway.Response(
          statusCode: .created,
          headers: TodoController.sharedHeader,
          payload: todo,
          encoder: self.createResponseEncoder(request))
      }
  }
  
  func deleteAll(request: APIGateway.Request, context: Context) -> EventLoopFuture<APIGateway.Response> {
    return self.store.deleteAllTodos()
      .flatMapThrowing { _ -> APIGateway.Response in
        return try APIGateway.Response(
          statusCode: .ok,
          headers: TodoController.sharedHeader,
          payload: [TodoItem](),
          encoder: self.createResponseEncoder(request))
      }
  }
  
  func getTodo(request: APIGateway.Request, context: Context) -> EventLoopFuture<APIGateway.Response> {
    guard let id = request.pathParameters?["id"] else {
      return context.eventLoop.makeSucceededFuture(APIGateway.Response(statusCode: .badRequest))
    }
    
    return self.store.getTodo(id: id)
      .flatMapThrowing { (todo) -> APIGateway.Response in
        return try APIGateway.Response(
          statusCode: .ok,
          headers: TodoController.sharedHeader,
          payload: todo,
          encoder: self.createResponseEncoder(request))
      }
      .flatMapErrorThrowing { (error) -> APIGateway.Response in
        switch error {
        case TodoError.notFound:
          return APIGateway.Response(statusCode: .notFound)
        default:
          throw error
        }
      }
  }
  
  func deleteTodo(request: APIGateway.Request, context: Context) -> EventLoopFuture<APIGateway.Response> {
    guard let id = request.pathParameters?["id"] else {
      return context.eventLoop.makeSucceededFuture(APIGateway.Response(statusCode: .badRequest))
    }
    
    return self.store.deleteTodos(ids: [id])
      .flatMapThrowing { _ -> APIGateway.Response in
        return try APIGateway.Response(
          statusCode: .ok,
          headers: TodoController.sharedHeader,
          payload: [TodoItem](),
          encoder: self.createResponseEncoder(request))
      }
  }
  
  func patchTodo(request: APIGateway.Request, context: Context) -> EventLoopFuture<APIGateway.Response> {
    guard let id = request.pathParameters?["id"] else {
      return context.eventLoop.makeSucceededFuture(APIGateway.Response(statusCode: .badRequest))
    }
    
    let patchTodo: PatchTodo
    do {
      patchTodo = try request.payload()
    }
    catch {
      return context.eventLoop.makeFailedFuture(error)
    }
    
    return self.store.patchTodo(id: id, patch: patchTodo)
      .flatMapThrowing { (todo) -> APIGateway.Response in
        return try APIGateway.Response(
          statusCode: .ok,
          headers: TodoController.sharedHeader,
          payload: todo,
          encoder: self.createResponseEncoder(request))
      }
  }

  private func createResponseEncoder(_ request: APIGateway.Request) -> JSONEncoder {
    let encoder = JSONEncoder()
    
    guard let proto = request.headers?["X-Forwarded-Proto"], let host = request.headers?["Host"] else {
      return encoder
    }
    
    if request.requestContext.apiId != "1234567890" {
      encoder.userInfo[.baseUrl] = URL(string: "\(proto)://\(host)/\(request.requestContext.stage)")!
    }
    else { //local
      encoder.userInfo[.baseUrl] = URL(string: "\(proto)://\(host)")!
    }
    
    return encoder
  }
  
}
