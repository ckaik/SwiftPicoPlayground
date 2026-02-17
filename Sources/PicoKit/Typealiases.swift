/// Numeric GPIO identifier used by Pico SDK pin APIs.
public typealias PinID = UInt32

/// Numeric PWM slice identifier returned by Pico SDK mapping APIs.
///
/// A slice owns the shared PWM timing configuration (divider/TOP) for
/// all channels attached to it.
public typealias SliceID = UInt32
