
let CHAR = 11

var a: [Int] = []

func countIt() {
  let n = countPresence(a, n: CHAR)
  print("count of number \(CHAR): \(n)")
}

fillArray(&a);
countIt()

a = [Int](repeating: 0, count: ITERATIONS)
fillArray2(&a);
countIt()
