
import Glibc
import CSua
import Sua


var tOdd = Thread() {
  for nOdd in 0..<400 {
    IO.sleep(0.05)
    if nOdd % 2 != 0 {
      print("Odd: \(nOdd)")
    }
  }
}

func factorial(n: Int) -> Int {
  print("Factorial: \(n)")
  IO.sleep(0.1)
  return n == 0 ? 1 : n * factorial(n - 1)
}

var tFactorial = Thread() {
  for fi in 0..<21 {
    print("Factorial of \(fi)!: \(factorial(fi))")
  }
}

func calcPrime(n: Int) -> Bool {
  if n < 2 {
    return false
  }
  for i in 2..<n {
    if n % i == 0 {
      return false
    }
  }
  return true
}

var tPrime = Thread() {
  for pi in 1..<400 {
    IO.sleep(0.025)
    print("Prime check of \(pi): \(calcPrime(pi))")
  }
}

try tOdd.join()
try tFactorial.join()
try tPrime.join()
