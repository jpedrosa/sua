
// This is a Swift version of a custom benchmark first introduced on the Wren
// project here:
// https://github.com/munificent/wren/blob/master/test/benchmark/method_call.dart

import Sua


class Toggle {

  var state = false

  init(startState: Bool) {
    state = startState
  }

  var value: Bool {
    get { return state }
  }

  func activate() -> Toggle {
    state = !state
    return self
  }

}


class NthToggle: Toggle {

  var count = 0
  var countMax = 0

  init(startState: Bool, maxCounter: Int) {
    super.init(startState: startState)
    countMax = maxCounter
    count = 0
  }

  override func activate() -> Toggle {
    count = count + 1
    if (count >= countMax) {
      let _ = super.activate()
      count = 0
    }

    return self
  }
}


var sw = Stopwatch()
sw.start()

let n = 100000
var val = true
let toggle = Toggle(startState: val)

for i in 0..<n {
  val = toggle.activate().value
  val = toggle.activate().value
  val = toggle.activate().value
  val = toggle.activate().value
  val = toggle.activate().value
  val = toggle.activate().value
  val = toggle.activate().value
  val = toggle.activate().value
  val = toggle.activate().value
  val = toggle.activate().value
}

print(toggle.value)

val = true
let ntoggle = NthToggle(startState: val, maxCounter: 3)

for i in 0..<n {
  val = ntoggle.activate().value
  val = ntoggle.activate().value
  val = ntoggle.activate().value
  val = ntoggle.activate().value
  val = ntoggle.activate().value
  val = ntoggle.activate().value
  val = ntoggle.activate().value
  val = ntoggle.activate().value
  val = ntoggle.activate().value
  val = ntoggle.activate().value
}

print(ntoggle.value)
sw.stop()
print("elapsed: \(sw.elapsedSeconds)")
