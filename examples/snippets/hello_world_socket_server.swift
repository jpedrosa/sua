
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
print("Trying to start server on http://\(addressName):\(portNumber)/")

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

withUnsafePointer(&address) { ptr in
  bind(fd, UnsafePointer<sockaddr>(ptr), addrlen)
}

var buffer = [UInt8](count: 1024, repeatedValue: 0)

var clientAddr = sockaddr_in()
var clientAddrLen = UInt32(sizeofValue(clientAddr))

while true {
  listen(fd, SOMAXCONN)
  var cfd = withUnsafePointer(&clientAddr) { (ptr) -> Int32 in
    return accept(fd, UnsafeMutablePointer<sockaddr>(ptr), &clientAddrLen)
  }
  if cfd < 0 {
    print("bug: \(cfd) errno: \(errno)")
//    break
  }
  defer {
    close(cfd)
  }
  var n = recv(cfd, &buffer, 1024, 0)
  write(cfd, "Hello World\n", 12)
}
