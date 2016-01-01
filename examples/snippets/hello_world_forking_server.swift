
// This is a version based on a simpler version created for the C language:
// https://github.com/eatonphil/referenceserver/blob/master/c/server.c

import Glibc


let fd = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
if fd == -1 {
  print("Error: could not start the socket.")
}
defer {
  close(fd)
}

var addressName = "127.0.0.1"
var address = sockaddr_in()
address.sin_family = UInt16(AF_INET)
address.sin_addr.s_addr = inet_addr(addressName)
var portNumber: UInt16 = 9123
print("Trying to start server on \(addressName):\(portNumber)")

// Create our own version of the C function htons().
var reversePortNumber = withUnsafePointer(&portNumber) { (ptr) -> UInt16 in
  var ap = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(ptr),
      count: sizeofValue(portNumber))
  var n: UInt16 = 0
  withUnsafePointer(&n) { np in
    var np = UnsafeMutableBufferPointer<UInt8>(
          start: UnsafeMutablePointer<UInt8>(np), count: sizeofValue(n))
    np[0] = ap[1]
    np[1] = ap[0]
  }
  return n
}

address.sin_port = reversePortNumber

var addrlen = UInt32(sizeofValue(address))

let bindResult = withUnsafePointer(&address) { (ptr) -> Int32 in
  return bind(fd, UnsafePointer<sockaddr>(ptr), addrlen)
}

if bindResult == -1 {
  print("Error: Could not start the server. Port may already be in use by " +
      "another process.")
  exit(1)
}

var buffer = [UInt8](count: 1024, repeatedValue: 0)

var clientAddr = sockaddr_in()
var clientAddrLen = UInt32(sizeofValue(clientAddr))

listen(fd, SOMAXCONN)

func process(cfd: Int32) {
  defer {
    close(cfd)
  }
  var buffer = [UInt8](count: 1024, repeatedValue: 0)
  recv(cfd, &buffer, 1024, 0)
  write(cfd, "Hello World\n", 12)
}

signal(SIGCHLD, SIG_IGN)

while true {
  var cfd = withUnsafePointer(&clientAddr) { (ptr) -> Int32 in
    return accept(fd, UnsafeMutablePointer<sockaddr>(ptr), &clientAddrLen)
  }
  if cfd < 0 {
    print("bug: \(cfd) errno: \(errno)")
//    break
  }
  // Create the child process.
  let pid = fork()

  if pid < 0 {
    print("Error: fork failed.")
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
