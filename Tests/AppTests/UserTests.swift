@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class UserTests: XCTestCase {
  
  let usersName = "Alice"
  let usersUsername = "alicea"
  let usersURI = "/api/users/"
  var app: Application!
  var conn: PostgreSQLConnection!
  
  override func setUp() {
    try! Application.reset()
    app = try! Application.testable()
    conn = try! app.newConnection(to: .psql).wait()
  }
  
  override func tearDown() {
    conn.close()
    try? app.syncShutdownGracefully()
  }
  
  func testUsersCanBeRetrievedFromAPI() throws {
    let user = try User.create(name: usersName, username: usersUsername, on: conn)
    _ = try User.create(on: conn)
    
    let users = try app.getResponse(to: usersURI, decodeTo: [User].self)
    
    XCTAssertEqual(users.count, 2)
    XCTAssertEqual(users[0].name, user.name)
    XCTAssertEqual(users[0].username, user.username)
    XCTAssertEqual(users[0].id, user.id)
  }
  
  func testUserCanBeSavedWithAPI() throws {
    let user = User(name: usersName, username: usersUsername)
    let receivedUser = try app.getResponse(
      to: usersURI,
      method: .POST,
      headers: ["Content-Type": "application/json"],
      data: user,
      decodeTo: User.self
    )
    
    XCTAssertEqual(receivedUser.name, user.name)
    XCTAssertEqual(receivedUser.username, user.username)
    XCTAssertNotNil(receivedUser.id)
    
    let users = try app.getResponse(to: usersURI, decodeTo: [User].self)
    XCTAssertEqual(users.count, 1)
    XCTAssertEqual(users[0].name, receivedUser.name)
    XCTAssertEqual(users[0].username, receivedUser.username)
    XCTAssertEqual(users[0].id, receivedUser.id)
  }
  
  func testGettingASingleUserFromTheAPI() throws {
    let user = try User.create(name: usersName, username: usersUsername, on: conn)
    let receivedUser = try app.getResponse(to: "\(usersURI)/\(user.id!)", decodeTo: User.self)
    XCTAssertEqual(user.name, receivedUser.name)
    XCTAssertEqual(user.username, receivedUser.username)
    XCTAssertEqual(user.id, receivedUser.id)
  }
  
  func testGettingAUsersAcronymsFromTheAPI() throws {
    let user = try User.create(on: conn)
    
    let short = "OMG"
    let long = "Oh My God"
    
    let acronym1 = try Acronym.create(short: short, long: long, user: user, on: conn)
    _ = try Acronym.create(short: "LOL", long: "Laugh Ont Loud", user: user, on: conn)
    
    let acronyms = try app.getResponse(to: "\(usersURI)/\(user.id!)/acronyms", decodeTo: [Acronym].self)
    XCTAssertEqual(acronyms.count, 2)
    XCTAssertEqual(acronyms[0].short, acronym1.short)
    XCTAssertEqual(acronyms[0].long, acronym1.long)
    XCTAssertEqual(acronyms[0].id, acronym1.id)
  }
  
  static let allTests = [
    ("testUsersCanBeRetrievedFromAPI", testUsersCanBeRetrievedFromAPI),
    ("testUserCanBeSavedWithAPI", testUserCanBeSavedWithAPI),
    ("testGettingASingleUserFromTheAPI", testGettingASingleUserFromTheAPI),
    ("testGettingAUsersAcronymsFromTheAPI", testGettingAUsersAcronymsFromTheAPI)
  ]
  
}
