public struct PWMTickContext {
  public let divider: UInt32
  public var tick: UInt32
  public let totalTicks: UInt32

  public init(totalTicks: UInt32, divider: UInt32 = 1, tick: UInt32 = 0) {
    self.totalTicks = max(1, totalTicks)
    self.divider = max(1, divider)
    self.tick = tick
  }

  public static func ticks(for durationSeconds: Float, wrapHz: UInt32, divider: UInt32 = 1)
    -> UInt32
  {
    let clampedDivider = max(1, divider)
    let ticks = Float(wrapHz) * durationSeconds / Float(clampedDivider)
    return UInt32(max(1, ticks))
  }

  public static func divider(forUpdateHz updateHz: Float, wrapHz: UInt32) -> UInt32 {
    let safeUpdateHz = max(1, updateHz)
    let divider = Float(wrapHz) / safeUpdateHz
    return UInt32(max(1, divider))
  }

  public static func divider(forTickMs tickMs: Float, wrapHz: UInt32) -> UInt32 {
    let safeMs = max(1, tickMs)
    let updateHz = 1000.0 / safeMs
    return divider(forUpdateHz: updateHz, wrapHz: wrapHz)
  }

  @discardableResult
  public mutating func advanceIfNeeded(onWrap wrapCount: UInt32) -> Bool {
    if wrapCount % divider == 0 {
      if tick < totalTicks { tick += 1 }
      return true
    }
    return false
  }

  public var tFixed: UInt16 {
    let clamped = min(tick, totalTicks)
    return UInt16((clamped * 65535) / totalTicks)
  }
}
