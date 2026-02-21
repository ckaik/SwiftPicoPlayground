/// Common HTTP status codes used by the lightweight embedded HTTP server.
public enum HTTPStatus: Int32 {
  case noContent = 204
  case ok = 200
  case badRequest = 400
  case methodNotAllowed = 405
  case notFound = 404
  case internalServerError = 500
}
