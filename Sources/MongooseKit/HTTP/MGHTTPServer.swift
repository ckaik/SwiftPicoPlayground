import Mongoose

public final class MGHTTPServer {
  fileprivate var listener: UnsafeMutablePointer<mg_connection>?
  private let port: UInt16

  public init(port: UInt16) {
    self.port = port
  }

  public func start(address: String = "0.0.0.0") {
    guard listener == nil else { return }

    let context = Unmanaged.passUnretained(self).toOpaque()
    listener = MGManager.shared.withManagerPointer { manager in
      "http://\(address):\(port)".withCString { url in
        mg_http_listen(manager, url, httpEventHandler, context)
      }
    }
  }

  public func stop() {
    guard let listener else { return }
    listener.pointee.is_closing = 1
    self.listener = nil
  }

  deinit {
    stop()
  }

  fileprivate func handle(
    _ message: mg_http_message, connection: UnsafeMutablePointer<mg_connection>
  ) {
    let response = HTTPResponse(
      status: .notFound,
      headers: [
        .init("Content-Type", value: "text/plain")
      ],
      body: "Not Found"
    )

    swift_mg_http_reply(
      connection,
      response.status.rawValue,
      response.headerString(),
      response.body
    )
  }
}

private func httpEventHandler(
  conn: UnsafeMutablePointer<mg_connection>?, ev: Int32, evData: UnsafeMutableRawPointer?
) {
  guard
    let conn,
    let rawServer = conn.pointee.fn_data
  else {
    return
  }

  let server = Unmanaged<MGHTTPServer>.fromOpaque(rawServer).takeUnretainedValue()

  switch Int(ev) {
  case MG_EV_HTTP_MSG:
    guard let messagePointer = evData?.assumingMemoryBound(to: mg_http_message.self) else {
      return
    }

    server.handle(messagePointer.pointee, connection: conn)
  case MG_EV_CLOSE:
    if conn == server.listener {
      server.listener = nil
    }
  default:
    break
  }
}
