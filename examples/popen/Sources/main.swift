
import Glibc
import Sua
import CSua


try PopenStream.readLines("ls -l /home/dewd/t_") { s in
  Stdout.write(s ?? "")
}

try PopenStream.readLines("lssdsdsd -l /home/dewd/t_") { s in
  Stdout.write(s ?? "")
}

try PopenStream.readLines("find /home/dewd/t_ -type f") { s in
  Stdout.write(s ?? "")
}

try IO.popen("cd /home/dewd/t_ && grep -ir a.*b") { s in
  Stdout.write(s ?? "")
}

try PopenStream.readBytes("ls -l /home/dewd/t_") { a, len in
  Stdout.writeBytes(a, maxBytes: len)
}

try PopenStream.readBytes("lssdsdsd -l /home/dewd/t_") { a, len in
  Stdout.writeBytes(a, maxBytes: len)
}

try PopenStream.readBytes("find /home/dewd/t_ -type f") { a, len in
  Stdout.writeBytes(a, maxBytes: len)
}

try IO.popenBytes("cd /home/dewd/t_ && grep -ir a.*b") { a, len in
  Stdout.writeBytes(a, maxBytes: len)
}
