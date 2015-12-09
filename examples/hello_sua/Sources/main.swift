
import Glibc
import Sua

p("Hello, Sua!")

let a = "|/-\\|/-\\".characters
var iterations = 10

func label(c: Character) {
  var s = "\r"
  s.append(c)
  s += " Welcome! "
  s.append(c)
  Stdout.write(s)
}

while iterations > 0 {
  for c in a {
    label(c)
    IO.sleep(0.08)
  }
  iterations -= 1
}

label(a.first!)
print("")
