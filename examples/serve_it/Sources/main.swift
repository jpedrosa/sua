
import Glibc
import Sua


p(AI_ADDRCONFIG)
p(IPPROTO_TCP)


let fd = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
if fd == -1 {
  p("Error: could not start the socket.")
}
defer {
  close(fd)
}

var address = sockaddr_in()
address.sin_family = UInt16(AF_INET)
address.sin_addr.s_addr = inet_addr("127.0.0.1") //INADDR_ANY
var portNumber: UInt16 = 9123

address.sin_port = ByteOrder.htons(portNumber)

var addrlen = UInt32(sizeofValue(address))

let bindResult = withUnsafePointer(&address) { (ptr) -> Int32 in
  return bind(fd, UnsafePointer<sockaddr>(ptr), addrlen)
}

if bindResult == -1 {
  p("Error: Failed to bind.")
  exit(0)
}

var clientAddr = sockaddr_in()
var clientAddrLen = UInt32(sizeofValue(clientAddr))

listen(fd, SOMAXCONN)

func process(cfd: Int32) {
  defer {
    close(cfd)
  }
  var buffer = [UInt8](count: 1024, repeatedValue: 0)
  recv(cfd, &buffer, 1024, 0)
  write(cfd, "hello world\n", 12)
}

signal(SIGCHLD, SIG_IGN)

while true {
  var cfd = withUnsafePointer(&clientAddr) { (ptr) -> Int32 in
    return accept(fd, UnsafeMutablePointer<sockaddr>(ptr), &clientAddrLen)
  }
  if cfd < 0 {
    p("bug: \(cfd) errno: \(errno)")
//    break
  }
  // Create the child process.
  let pid = fork()

  if pid < 0 {
    p("Error: failed to fork.")
    exit(1)
  }

  if pid == 0 {
    // This is the child process.
    close(fd)
    defer {
      exit(0)
    }
    process(cfd)
  } else {
    close(cfd)
  }
}
