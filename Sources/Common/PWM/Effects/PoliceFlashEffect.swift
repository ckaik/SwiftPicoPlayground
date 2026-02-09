public struct PoliceFlashEffect: PWMEffect {
  private enum Phase: Int, CaseIterable {
    case on1
    case off1
    case on2
    case off2

    var next: Phase {
      guard let index = Phase.allCases.firstIndex(of: self) else {
        return Phase.allCases[0]
      }

      let nextIndex = Phase.allCases.index(after: index)
      return nextIndex == Phase.allCases.endIndex ? Phase.allCases[0] : Phase.allCases[nextIndex]
    }
  }

  private let ticksOn: UInt32
  private let ticksGap: UInt32
  private let ticksPause: UInt32
  private let offsetTicks: UInt32
  private var phase: Phase
  private var remainingTicks: UInt32
  private var isPrimed = false

  public init(
    tickMs: Float,
    offsetMs: Float = 0,
    onMs: Float = 60,
    gapMs: Float = 40,
    pauseMs: Float = 200
  ) {
    self.ticksOn = PoliceFlashEffect.ticks(forMs: onMs, tickMs: tickMs)
    self.ticksGap = PoliceFlashEffect.ticks(forMs: gapMs, tickMs: tickMs)
    self.ticksPause = PoliceFlashEffect.ticks(forMs: pauseMs, tickMs: tickMs)
    self.offsetTicks = PoliceFlashEffect.ticks(forMs: offsetMs, tickMs: tickMs)
    self.phase = .on1
    self.remainingTicks = self.ticksOn
  }

  private var isOnPhase: Bool {
    phase == .on1 || phase == .on2
  }

  public mutating func level(for pin: PinID, wrap: UInt16, onWrap wrapCount: UInt32) -> UInt16 {
    if !isPrimed {
      if offsetTicks > 0 {
        phase = .off2
        remainingTicks = offsetTicks
      }
      isPrimed = true
    }

    if remainingTicks == 0 {
      phase = phase.next
      remainingTicks = ticks(for: phase)
    }

    remainingTicks -= 1
    return isOnPhase ? wrap : 0
  }

  private func ticks(for phase: Phase) -> UInt32 {
    switch phase {
    case .on1, .on2: ticksOn
    case .off1: ticksGap
    case .off2: ticksPause
    }
  }

  private static func ticks(forMs ms: Float, tickMs: Float) -> UInt32 {
    let safeTick = max(1, tickMs)
    let count = ms / safeTick
    return UInt32(max(1, Int(count.rounded())))
  }
}
