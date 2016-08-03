
import Glibc
import Sua


p(a: "Hello, Sua!")

let a = "|/-\\|/-\\".characters

func label(c: Character) {
  var s = "\r"
  s.append(c)
  s += " Welcome! "
  s.append(c)
  Stdout.write(s: s)
}

for _ in 0..<10 {
  for c in a {
    label(c: c)
    IO.sleep(f: 0.08)
  }
}

label(c: a.first!)
print("")
