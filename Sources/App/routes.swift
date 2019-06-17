import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  let arconymsController = AcronymsController()
  try router.register(collection: arconymsController)
}
