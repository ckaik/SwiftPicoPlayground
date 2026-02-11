/// The WiFi authentication modes supported by the CYW43 wireless chip.
///
/// Each case maps directly to the corresponding `CYW43_AUTH_*` constant
/// defined in the Pico SDK and carries the same raw value, so it can be
/// passed straight to the C driver.
public enum WiFiAuthenticationMode: UInt32 {
  /// Open / no authentication.
  case open = 0x0000_0000

  /// WPA with TKIP cipher (pre-shared key).
  case wpaTkipPsk = 0x0020_0002

  /// WPA2 with AES cipher (pre-shared key).
  case wpa2AesPsk = 0x0040_0004

  /// WPA2 with mixed TKIP/AES ciphers (pre-shared key).
  case wpa2MixedPsk = 0x0040_0006

  /// WPA3-SAE with AES cipher (pre-shared key).
  case wpa3SaeAesPsk = 0x0100_0004

  /// WPA3/WPA2 transitional with AES cipher (pre-shared key).
  case wpa3Wpa2AesPsk = 0x0140_0004
}
