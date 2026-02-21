/// Common Pico SDK error codes exposed as Swift `Error` values.
public enum PicoError: Int32, Error {
  /// Unspecified failure.
  case generic = -1
  /// Operation exceeded its timeout.
  case timeout = -2
  /// Expected data was unavailable.
  case noData = -3
  /// Operation was not permitted in the current context.
  case notPermitted = -4
  /// One or more arguments were invalid.
  case invalidArgument = -5
  /// I/O operation failed.
  case io = -6
  /// Authentication failed.
  case badAuth = -7
  /// Connection attempt failed.
  case connectFailed = -8
  /// System resources were insufficient.
  case insufficientResources = -9
  /// Address parameter was invalid.
  case invalidAddress = -10
  /// Memory alignment requirements were not met.
  case badAlignment = -11
  /// Object or peripheral was in an invalid state.
  case invalidState = -12
  /// Destination buffer capacity was insufficient.
  case bufferTooSmall = -13
  /// Required precondition was not satisfied.
  case preconditionNotMet = -14
  /// Underlying data changed unexpectedly.
  case modifiedData = -15
  /// Data payload was invalid or malformed.
  case invalidData = -16
  /// Requested item could not be found.
  case notFound = -17
  /// Requested change is unsupported.
  case unsupportedModification = -18
  /// Resource requires a lock before modification.
  case lockRequired = -19
  /// Version mismatch between components.
  case versionMismatch = -20
  /// Resource is already in use.
  case resourceInUse = -21
  /// Non-standard fallback value for unknown error codes.
  case unknown = -1337
}
