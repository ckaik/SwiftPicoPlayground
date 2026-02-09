/// Repeating timer wrapper around the Pico SDK alarm API.
///
/// The timer cancels itself automatically when the instance is released, and
/// it can be stopped explicitly via ``stop()``.
public final class Timer {
  /// Strategy for when the next tick is scheduled.
  ///
  /// - ``afterCallback``: Schedules after the callback completes, so long
  ///   callbacks push future ticks back.
  /// - ``onTick``: Schedules anchored to the tick time to keep cadence steady
  ///   even if callbacks take time.
  public enum Scheduling {
    case afterCallback
    case onTick
  }

  /// Flag set to true once the timer has been stopped or a tick handler
  /// returns `false`.
  fileprivate(set) public var isInvalidated = false

  fileprivate(set) var cTimer: repeating_timer_t = .init()
  let onTick: (Timer) -> Bool

  fileprivate init(onTick: @escaping (Timer) -> Bool) {
    self.onTick = onTick
  }

  deinit {
    stop()
  }

  /// Starts a repeating timer.
  ///
  /// - Parameters:
  ///   - durationMs: Interval in milliseconds between ticks.
  ///   - scheduleNext: When to schedule the next tick (see ``Scheduling``).
  ///   - onTick: Callback invoked for each tick; return `true` to continue
  ///     ticking or `false` to stop and invalidate the timer.
  /// - Returns: A running ``Timer`` instance, or `nil` if registration fails.
  @discardableResult
  public class func start(
    durationMs: Int32,
    scheduleNext: Scheduling = .afterCallback,
    onTick: @escaping (Timer) -> Bool
  ) -> Timer? {
    let duration: Int32 =
      switch scheduleNext {
      case .afterCallback: abs(durationMs)
      case .onTick: -abs(durationMs)
      }

    return TimerRegistry.shared.new(durationMs: duration, onTick: onTick)
  }

  /// Stops the timer, marks it invalidated, and cancels further ticks.
  ///
  /// - Returns: `true` if the underlying cancellation succeeds, otherwise
  ///   `false`.
  @discardableResult
  public func stop() -> Bool {
    TimerRegistry.shared.stop(timer: self)
  }
}

private class TimerRegistry {
  static let shared = TimerRegistry()

  private var timers: [alarm_id_t: Timer] = [:]

  private init() {}

  func new(durationMs: Int32, onTick: @escaping (Timer) -> Bool) -> Timer? {
    let timer = Timer(onTick: onTick)
    let success = add_repeating_timer_ms(
      durationMs,
      _timerTicked,
      nil,
      &timer.cTimer
    )

    guard success else { return nil }

    timers[timer.cTimer.alarm_id] = timer
    return timer
  }

  func stop(timer: Timer) -> Bool {
    timers[timer.cTimer.alarm_id] = nil
    timer.isInvalidated = true
    return cancel_repeating_timer(&timer.cTimer)
  }

  func handleTimerTick(_ cTimer: UnsafeMutablePointer<repeating_timer_t>?) -> Bool {
    guard
      let id = cTimer?.pointee.alarm_id,
      let timer = timers[id]
    else {
      return false
    }

    if !timer.onTick(timer) {
      timers[id]?.isInvalidated = true
      timers[id] = nil
      return false
    }

    return true
  }
}

private func _timerTicked(_ timer: UnsafeMutablePointer<repeating_timer_t>?) -> Bool {
  TimerRegistry.shared.handleTimerTick(timer)
}
