
import Glibc
import Sua
import CSua


try Popen.readLines(command: "ls -l /home/dewd/t_") { s in
  Stdout.write(s ?? "")
}

try Popen.readLines(command: "lssdsdsd -l /home/dewd/t_") { s in
  Stdout.write(s ?? "")
}

try Popen.readLines(command: "find /home/dewd/t_ -type f") { s in
  Stdout.write(s ?? "")
}

try Popen.readLines(command: "cd /home/dewd/t_ && grep -ir a.*b") { s in
  Stdout.write(s ?? "")
}

try Popen.readByteLines(command: "ls -l /home/dewd/t_") { a, len in
  Stdout.write(bytes: a, max: len)
}

try Popen.readByteLines(command: "lssdsdsd -l /home/dewd/t_") { a, len in
  Stdout.write(bytes: a, max: len)
}

try Popen.readByteLines(command: "find /home/dewd/t_ -type f") { a, len in
  Stdout.write(bytes: a, max: len)
}

try Popen.readByteLines(command: "cd /home/dewd/t_ && grep -ir a.*b") {
    a, len in
  Stdout.write(bytes: a, max: len)
}
