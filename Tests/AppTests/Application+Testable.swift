import Vapor
import App
import FluentPostgreSQL

extension Application {
  
  static func testable(envArgs: [String]? = nil) throws -> Application {
    var config = Config.default()
    var services = Services.default()
    var env = Environment.testing
    
    if let envArgs = envArgs {
      env.arguments = envArgs
    }

    try App.configure(&config, &env, &services)
    let app = try Application(config: config, environment: env, services: services)
    try App.boot(app)
    return app
  }
  
  static func reset() throws {
    let revertEnvironmentArgs = ["vapor", "revert", "--all", "-y"]
    try Application.testable(envArgs: revertEnvironmentArgs)
      .asyncRun()
      .wait()
    
    let migrateEnvArgs = ["vapor", "migrate", "-y"]
    try Application.testable(envArgs: migrateEnvArgs)
      .asyncRun()
      .wait()
  }
  
  func sendRequest<T: Content>(
    to path: String,
    method: HTTPMethod,
    headers: HTTPHeaders = .init(),
    body: T? = nil
  ) throws -> Response {
    let responder = try make(Responder.self)
    let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
    let wrappedRequest = Request(http: request, using: self)

    if let body = body {
      try wrappedRequest.content.encode(body)
    }
    
    return try responder.respond(to: wrappedRequest).wait()
  }
  
  func sendRequest(
    to path: String,
    method: HTTPMethod,
    headers: HTTPHeaders = .init()
  ) throws -> Response {
    return try sendRequest(to: path, method: method, headers: headers, body: EmptyContent?.none)
  }
  
  func sendRequest<T: Content>(
    to path: String,
    method: HTTPMethod,
    headers: HTTPHeaders = .init(),
    data: T
  ) throws {
    _ = try sendRequest(to: path, method: method, headers: headers, body: data)
  }
  
  func getResponse<C: Content, T: Decodable>(
    to path: String,
    method: HTTPMethod = .GET,
    headers: HTTPHeaders = .init(),
    data: C? = nil,
    decodeTo type: T.Type
  ) throws -> T {
    let response = try sendRequest(
      to: path,
      method: method,
      headers: headers,
      body: data
    )
    return try response.content.decode(type).wait()
  }
  
  func getResponse<T: Decodable>(
    to path: String,
    method: HTTPMethod = .GET,
    headers: HTTPHeaders = .init(),
    decodeTo type: T.Type
  ) throws -> T {
    return try getResponse(
      to: path,
      method: method,
      headers: headers,
      data: EmptyContent?.none,
      decodeTo: type
    )
  }
  
}

struct EmptyContent: Content { }
