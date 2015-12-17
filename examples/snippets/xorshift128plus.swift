

var state0: UInt64 = 1
var state1: UInt64 = 2

func xorshift128plus() {
  var s1 = state0
  let s0 = state1
  state0 = s0
  s1 ^= s1 << 23
  s1 ^= s1 >> 17
  s1 ^= s0
  s1 ^= s0 >> 26
  state1 = s1
}

xorshift128plus()

debugPrint(state0, state1)
