
import Glibc
import Sua
import CSua


try Popen.readLines("ls -l /home/dewd/t_") { s in
  Stdout.write(s ?? "")
}

try Popen.readLines("lssdsdsd -l /home/dewd/t_") { s in
  Stdout.write(s ?? "")
}

try Popen.readLines("find /home/dewd/t_ -type f") { s in
  Stdout.write(s ?? "")
}

try Popen.readLines("cd /home/dewd/t_ && grep -ir a.*b") { s in
  Stdout.write(s ?? "")
}

try Popen.readByteLines("ls -l /home/dewd/t_") { a, len in
  Stdout.writeBytes(a, maxBytes: len)
}

try Popen.readByteLines("lssdsdsd -l /home/dewd/t_") { a, len in
  Stdout.writeBytes(a, maxBytes: len)
}

try Popen.readByteLines("find /home/dewd/t_ -type f") { a, len in
  Stdout.writeBytes(a, maxBytes: len)
}

try Popen.readByteLines("cd /home/dewd/t_ && grep -ir a.*b") { a, len in
  Stdout.writeBytes(a, maxBytes: len)
}
