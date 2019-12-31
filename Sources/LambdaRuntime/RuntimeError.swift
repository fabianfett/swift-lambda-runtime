enum RuntimeError: Error, Equatable {
  case unknown
  
  case missingEnvironmentVariable(String)
  case invalidHandlerName
  
  case invocationMissingHeader(String)
  case invocationMissingData
  
  case unknownLambdaHandler(String)
  
  case endpointError(String)
}
