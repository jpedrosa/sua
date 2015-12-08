
let CHAR = 11

var a: [Int] = []

func countIt() {
  let n = countPresence(a, n: CHAR)
  print("count of number \(CHAR): \(n)")
}

fillArray(&a);
countIt()

a = [Int](count: ITERATIONS, repeatedValue: 0)
fillArray2(&a);
countIt()
