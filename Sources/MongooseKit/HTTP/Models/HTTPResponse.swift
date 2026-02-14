public struct HTTPResponse {
  public let status: HTTPStatus
  public let headers: [HTTPHeader]
  public let body: String

  public init(status: HTTPStatus, headers: [HTTPHeader] = [], body: String) {
    self.status = status
    self.headers = headers
    self.body = body
  }
}

extension HTTPResponse {
  func headerString() -> String {
    var headersString = ""
    for header in headers {
      headersString += "\(header.field): \(header.value)\r\n"
    }
    return headersString
  }
}
