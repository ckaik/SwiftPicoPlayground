import CMongoose

func httpEventHandler(
  conn: UnsafeMutablePointer<mg_connection>?,
  ev: Int32,
  evData: UnsafeMutableRawPointer?
) {
  guard let conn, let rawServer = conn.pointee.fn_data else { return }

  let server = Unmanaged<HTTPServer>.fromOpaque(rawServer).takeUnretainedValue()

  switch Int(ev) {
  case MG_EV_HTTP_MSG:
    guard let messagePointer = evData?.assumingMemoryBound(to: mg_http_message.self) else { return }

    server.handle(messagePointer.pointee, connection: conn)
  case MG_EV_CLOSE:
    server.handleClose(conn)
  default:
    break
  }
}
