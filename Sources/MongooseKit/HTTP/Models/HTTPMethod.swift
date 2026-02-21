/// Supported HTTP request methods for `HTTPServer` route registration and dispatch.
public enum HTTPMethod: String, CaseIterable {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case patch = "PATCH"
  case delete = "DELETE"
  case head = "HEAD"
  case options = "OPTIONS"
}
