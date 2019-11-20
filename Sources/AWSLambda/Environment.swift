import Foundation

public struct Environment {
  
  public let lambdaRuntimeAPI: String
  public let handlerName     : String
  
  public let functionName    : String
  public let functionVersion : String
  public let logGroupName    : String
  public let logStreamName   : String
  public let memoryLimitInMB : String
  public let accessKeyId     : String
  public let secretAccessKey : String
  public let sessionToken    : String
  public let region          : String
  
  init(_ env: [String: String]) throws {
    
    guard let awsLambdaRuntimeAPI = env["AWS_LAMBDA_RUNTIME_API"] else {
      throw RuntimeError.missingEnvironmentVariable("AWS_LAMBDA_RUNTIME_API")
    }
    
    guard let handler = env["_HANDLER"] else {
      throw RuntimeError.missingEnvironmentVariable("_HANDLER")
    }

    guard let periodIndex = handler.firstIndex(of: ".") else {
      throw RuntimeError.invalidHandlerName
    }

    let handlerName = String(handler[handler.index(after: periodIndex)...])
    
    self.lambdaRuntimeAPI = awsLambdaRuntimeAPI
    self.handlerName      = handlerName
    
    self.functionName     = env["AWS_LAMBDA_FUNCTION_NAME"] ?? ""
    self.functionVersion  = env["AWS_LAMBDA_FUNCTION_VERSION"] ?? ""
    self.logGroupName     = env["AWS_LAMBDA_LOG_GROUP_NAME"] ?? ""
    self.logStreamName    = env["AWS_LAMBDA_LOG_STREAM_NAME"] ?? ""
    self.memoryLimitInMB  = env["AWS_LAMBDA_FUNCTION_MEMORY_SIZE"] ?? ""
    
    self.accessKeyId      = env["AWS_ACCESS_KEY_ID"] ?? ""
    self.secretAccessKey  = env["AWS_SECRET_ACCESS_KEY"] ?? ""
    self.sessionToken     = env["AWS_SESSION_TOKEN"] ?? ""
    
    self.region           = env["AWS_REGION"] ?? "us-east-1"
  }
}
