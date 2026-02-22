import CMongoose

extension MQTTClient {
  public func on(_ topic: String, handler: @escaping (MQTTMessage) -> Void) {
    handlers[topic] = handler
    subscribe(to: topic)
  }

  func subscribe() {
    for topic in topics {
      subscribe(to: topic)
    }
  }

  func subscribe(to topic: String) {
    guard let conn = currentConnection else { return }

    topic.withCString { topic in
      var opts = mg_mqtt_opts()
      opts.topic = mg_str_s(topic)
      mg_mqtt_sub(conn, &opts)
    }
    topics.insert(topic)
  }
}
