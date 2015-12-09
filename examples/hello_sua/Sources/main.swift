
import Glibc
import Sua

p("Hello, Sua!")

let a = "|/-\\|/-\\".characters

func label(c: Character) {
  var s = "\r"
  s.append(c)
  s += " Welcome! "
  s.append(c)
  Stdout.write(s)
}

for _ in 0..<10 {
  for c in a {
    label(c)
    IO.sleep(0.08)
  }
}

label(a.first!)
print("")
