
import Glibc

func formatDouble(f: Double, precision: Int = 2) -> String{
  var p = 1
  for _ in 0..<precision {
    p *= 10
  }
  let si = "\(Int(round((f * Double(p)))))"
  var s = ""
  let a = si.characters
  let len = a.count
  let dot = len - precision
  var i = 0
  for c in a {
    if i == dot {
      s += (i == 0 || i == 1 && f < 0) ? "0." : "."
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
