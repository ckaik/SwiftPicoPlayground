import MongooseKit

func startHTTPServer(ledMap: [String: LEDController]) -> HTTPServer {
  let http = HTTPServer(port: 8080)

  http.get("/pin/:pinId") { req in
    guard
      let pinId = req.pathParameters["pinId"],
      let led = ledMap[pinId]
    else {
      return .init(status: .badRequest, body: "pin not found")
    }

    let state =
      switch led.state {
      case .off: "off"
      case .on(let brightness): "on at brightness: \(brightness)"
      case .effect(let effect): "effect: \(effect)"
      }

    return .init(status: .ok, body: state)
  }

  http.put("/pin/:pinId/:state") { req in
    guard let state = req.pathParameters["state"]?.lowercased() else {
      return .init(status: .badRequest, body: "missing state")
    }

    enum NewState {
      case off
      case on(float: Float)
    }

    let newState: NewState? =
      switch state {
      case "off": NewState.off
      case "on": NewState.on(float: 1)
      default:
        if let double = Double(string: state) {
          NewState.on(float: Float(double))
        } else {
          nil
        }
      }

    guard let newState else {
      return .init(status: .badRequest, body: "invalid state")
    }

    guard
      let pinId = req.pathParameters["pinId"],
      let led = ledMap[pinId]
    else {
      return .init(status: .badRequest, body: "pin not found")
    }

    switch newState {
    case .off:
      led.off()
    case .on(let brightness):
      led.on(at: brightness)
    }

    return .init(status: .ok, body: "ok")
  }

  http.start()

  return http
}
