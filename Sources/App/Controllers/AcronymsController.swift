import Vapor
import Fluent

final class AcronymsController: RouteCollection {
  
  func boot(router: Router) throws {
    let acronymsRoutes = router.grouped("api", "acronyms")
    
    acronymsRoutes.get(use: getAllHandler)
    acronymsRoutes.post(Acronym.self, use: createHandler)
    acronymsRoutes.get(Acronym.parameter, use: getHandler)
    acronymsRoutes.put(Acronym.parameter, use: updateHandler)
    acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
    acronymsRoutes.get("search", use: searchHandler)
    acronymsRoutes.get("first", use: firstHandler)
    acronymsRoutes.get("sorted", use: sortedHandler)
  }
  
  func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
    return Acronym.query(on: req).all()
  }

  func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
    return acronym.save(on: req)
  }
  
  func getHandler(_ req: Request) throws -> Future<Acronym> {
    return try req.parameters.next(Acronym.self)
  }
  
  func updateHandler(_ req: Request) throws -> Future<Acronym> {
    return try flatMap(req.parameters.next(Acronym.self), req.content.decode(Acronym.self)) { acronym, updatedAcronym in
      acronym.short = updatedAcronym.short
      acronym.long = updatedAcronym.long
      return acronym.save(on: req)
    }
  }
  
  func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
    return try req.parameters.next(Acronym.self)
      .delete(on: req)
      .transform(to: .noContent)
  }
  
  func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
    guard let searchTerm = req.query[String.self, at: "term"] else {
      throw Abort(.badRequest)
    }
    
    return Acronym.query(on: req)
      .group(.or) { or in
        or.filter(\.long == searchTerm)
        or.filter(\.short == searchTerm)
      }
      .all()
  }
  
  func firstHandler(_ req: Request) throws -> Future<Acronym> {
    return Acronym.query(on: req)
      .first()
      .unwrap(or: Abort(.notFound))
  }
  
  func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
    return Acronym.query(on: req)
      .sort(\.short, .ascending)
      .all()
  }
  
}
