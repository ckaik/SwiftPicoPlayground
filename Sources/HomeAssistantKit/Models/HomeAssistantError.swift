import MongooseKit

public enum HomeAssistantError: Error {
  case mqtt(MQTTClientError)
}
