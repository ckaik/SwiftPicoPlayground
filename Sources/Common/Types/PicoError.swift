public enum PicoError: Int32, Error {
  case generic = -1
  case timeout = -2
  case noData = -3
  case notPermitted = -4
  case invalidArgument = -5
  case io = -6
  case badAuth = -7
  case connectFailed = -8
  case insufficientResources = -9
  case invalidAddress = -10
  case badAlignment = -11
  case invalidState = -12
  case bufferTooSmall = -13
  case preconditionNotMet = -14
  case modifiedData = -15
  case invalidData = -16
  case notFound = -17
  case unsupportedModification = -18
  case lockRequired = -19
  case versionMismatch = -20
  case resourceInUse = -21
  case unknown = 1337
}
