
let ITERATIONS = 1000000

func fillArray(_ a: inout [Int]) {
  var n = 0
  for _ in 0..<ITERATIONS {
    a.append(n)
    n += 1
    if n > 15 {
      n = 0
    }
  }
}

func fillArray2(_ a: inout [Int]) {
  var n = 0
  for i in 0..<ITERATIONS {
    a[i] = n
    n += 1
    if n > 15 {
      n = 0
    }
  }
}

func countPresence(_ a: [Int], n: Int) -> Int {
  var r = 0
  for c in a {
    if c == n {
      r += 1
    }
  }
  return r
}
