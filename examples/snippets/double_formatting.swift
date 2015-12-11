
import Glibc

func formatDouble(f: Double, precision: Int = 2) -> String{
  var p = 1
  for _ in 0..<precision {
    p *= 10
  }
  let neutral = abs(Int(round((f * Double(p)))))
  var s = ""
  let a = "\(neutral)".characters
  let len = a.count
  var dot = len - precision
  if f < 0 {
    s += "-"
  }
  if dot <= 0 {
    dot = 1
  }
  let pad = precision - len
  var i = 0
  while i <= pad {
    s += i == dot ? ".0" : "0"
    i += 1
  }
  for c in a {
    if i == dot {
      s += "."
    }
    s.append(c)
    i += 1
  }
  return s
}

func tp(f: Double, precision: Int = 2) {
  print("\(f) (precision: \(precision)) -> " +
      "\(formatDouble(f, precision: precision))")
}

func runBatch(f: Double) {
  tp(f, precision: 0)
  tp(f, precision: 1)
  tp(f)
  tp(f, precision: 3)
  tp(f, precision: 5)
  tp(f, precision: 7)
  tp(f, precision: 9)
  tp(f, precision: 11)
}

runBatch(12.3456789)
runBatch(0.123456789)
runBatch(-0.123456789)
runBatch(-1.23456789)
runBatch(1.0)
runBatch(0.00123456789)
runBatch(-0.00123456789)
runBatch(765210.00123456789)
runBatch(-8765210.00123456789)
