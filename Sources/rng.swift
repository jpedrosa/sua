import Glibc


// Class for Pseudo Random Number Generation.
// Its implementation is heavily inspired by the V8's own Pseudo Random Number
// Generator found at:
// https://github.com/v8/v8/blob/085fed0fb5c3b0136827b5d7c190b4bd1c23a23e/src/base/utils/random-number-generator.cc

public class RNG {

  public init() {
    var seed: UInt64 = 0
    var ts: timespec = timespec()
    clock_gettime(CLOCK_REALTIME, &ts)
    seed ^= UInt64(ts.tv_nsec) << 24
    clock_gettime(CLOCK_MONOTONIC, &ts)
    seed ^= UInt64(ts.tv_nsec) << 16
    seed ^= UInt64(clock()) << 8
    setSeed(seed)
  }

  var state0: UInt64 = 1
  var state1: UInt64 = 2

  func xorShift128() {
    var s1 = state0
    let s0 = state1
    state0 = s0
    s1 ^= s1 << 23
    s1 ^= s1 >> 17
    s1 ^= s0
    s1 ^= s0 >> 26
    state1 = s1
  }

  func isPowerOfTwo(x: Int) -> Bool {
    return ((x) != 0 && (((x) & ((x) - 1)) == 0))
  }

  // Returns an int between 0 and max.
  public func nextInt(max: Int) -> Int {

    // Fast path if max is a power of 2.
    if isPowerOfTwo(max) {
      return Int((UInt64(max) &* UInt64(next(31))) >> 31)
    }

    while (true) {
      let rnd = next(31)
      let val = rnd % max
      if rnd - val + (max - 1) >= 0 {
        return val
      }
    }
  }

  // Returns a random Double number between 0.0 and 1.0.
  // Referenced code in V8 and in this Mozilla thread:
  // https://bugzilla.mozilla.org/show_bug.cgi?id=322529
  public func nextDouble() -> Double {
    xorShift128()
    let u = state0 &+ state1
    let n = Double(u & ((UInt64(1) << 53) - 1))
    return n / Double(UInt64(1) << 53)
  }

  public func nextUInt64() -> UInt64 {
    xorShift128()
    return state0 &+ state1
  }

  func next(bits: Int) -> Int {
    xorShift128()
    let b = 64 - bits
    return Int((state0 &+ state1) >> UInt64(b))
  }

  public func setSeed(seed: UInt64) {
    state0 = murmurHash3(seed)
    state1 = murmurHash3(state0)
  }

  func murmurHash3(hash: UInt64) -> UInt64 {
    var h = hash
    h ^= h >> 33
    h = h &* 0xFF51AFD7ED558CCD
    h ^= h >> 33
    h = h &* 0xC4CEB9FE1A85EC53
    h ^= h >> 33
    return h
  }

}
