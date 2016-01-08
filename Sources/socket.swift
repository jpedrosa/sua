
import Glibc


public typealias CSocketAddress = sockaddr

public struct SocketAddress {

  public var hostName: String
  public var status: Int32 = 0

  public init(hostName: String) {
    self.hostName = hostName
  }

  mutating func prepareHints() -> addrinfo {
    status = 0 // Reset the status in case of subsequent calls.
    var hints = addrinfo()
    hints.ai_family = AF_INET
    hints.ai_socktype = Int32(SOCK_STREAM.rawValue)
    hints.ai_flags = AI_ADDRCONFIG
    hints.ai_protocol = Int32(IPPROTO_TCP)
    return hints
  }

  // This returns a value equivalent to a call to the C function inet_addr.
  // It can be used to supply the address to a line of code such as this one:
  // address.sin_addr.s_addr = inet_addr(ipString)
  // E.g.
  //     var sa = SocketAddress(hostName: "google.com")
  //     address.sin_addr.s_addr = sa.ip4ToUInt32()
  mutating public func ip4ToUInt32() -> UInt32? {
    var hints = prepareHints()
    var info = UnsafeMutablePointer<addrinfo>()
    status = getaddrinfo(hostName, nil, &hints, &info)
    defer {
      freeaddrinfo(info)
    }
    if status == 0 {
      return withUnsafePointer(&info.memory.ai_addr.memory) { ptr -> UInt32 in
        let sin = UnsafePointer<sockaddr_in>(ptr)
        return sin.memory.sin_addr.s_addr
      }
    }
    return nil
  }

  // Obtain the string representation of the resolved IP4 address.
  mutating public func ip4ToString() -> String? {
    var hints = prepareHints()
    var info = UnsafeMutablePointer<addrinfo>()
    status = getaddrinfo(hostName, nil, &hints, &info)
    defer {
      freeaddrinfo(info)
    }
    if status == 0 {
      return withUnsafePointer(&info.memory.ai_addr.memory) { ptr -> String? in
        let len = INET_ADDRSTRLEN
        let sin = UnsafePointer<sockaddr_in>(ptr)
        var sin_addr = sin.memory.sin_addr
        var descBuffer = [CChar](count: Int(len), repeatedValue: 0)
        if inet_ntop(AF_INET, &sin_addr, &descBuffer, UInt32(len)) != nil {
          return String.fromCString(descBuffer)
        }
        return nil
      }
    }
    return nil
  }

  // Obtain a list of the string representations of the resolved IP4 addresses.
  mutating public func ip4ToStringList() -> [String]? {
    var hints = prepareHints()
    var info = UnsafeMutablePointer<addrinfo>()
    status = getaddrinfo(hostName, nil, &hints, &info)
    defer {
      freeaddrinfo(info)
    }
    if status == 0 {
      var r: [String] = []
      var h = info.memory
      while true {
        let fam = h.ai_family
        let len = INET_ADDRSTRLEN
        var sockaddr = h.ai_addr.memory
        withUnsafePointer(&sockaddr) { ptr in
          let sin = UnsafePointer<sockaddr_in>(ptr)
          var sin_addr = sin.memory.sin_addr
          var descBuffer = [CChar](count: Int(len), repeatedValue: 0)
          if inet_ntop(fam, &sin_addr, &descBuffer, UInt32(len)) != nil {
            r.append(String.fromCString(descBuffer) ?? "")
          }
        }
        let next = h.ai_next
        if next == nil {
          break
        } else {
          h = next.memory
        }
      }
      return r
    }
    return nil
  }

  // Obtain the string representation of the resolved IP6 address.
  mutating public func ip6ToString() -> String? {
    var hints = prepareHints()
    hints.ai_family = AF_INET6
    var info = UnsafeMutablePointer<addrinfo>()
    status = getaddrinfo(hostName, nil, &hints, &info)
    defer {
      freeaddrinfo(info)
    }
    if status == 0 {
      return withUnsafePointer(&info.memory.ai_addr.memory) { ptr -> String? in
        let len = INET6_ADDRSTRLEN
        var sa = [Int8](count: Int(len), repeatedValue: 0)
        if getnameinfo(&info.memory.ai_addr.memory,
            UInt32(sizeof(sockaddr_in6)), &sa, UInt32(len), nil, 0,
              hints.ai_flags) == 0 {
          return String.fromCString(sa)
        }
        return nil
      }
    }
    return nil
  }

  // It will try to resolve the IP4 address and will return a C sockaddr based
  // on it, or the typealias we created for it called CSocketAddress.
  // This then could be used in a follow up call to the C bind function.
  // E.g.
  //     if let sa = ip4ToCSocketAddress(port) {
  //       var address = sa
  //       let addrlen = UInt32(sizeofValue(address))
  //       return bind(fd, &address, addrlen)
  //     }
  mutating public func ip4ToCSocketAddress(port: UInt16) -> CSocketAddress? {
    var address = sockaddr_in()
    address.sin_family = UInt16(AF_INET)
    if let na = ip4ToUInt32() {
      address.sin_addr.s_addr = na
      address.sin_port = port.bigEndian
      return withUnsafePointer(&address) { ptr -> sockaddr in
        return UnsafePointer<sockaddr>(ptr).memory
      }
    }
    return nil
  }

  // Handy method that does a couple of things in one go. It will first try
  // to resolve the given address. Upon success, it will try to bind it to the
  // given socket file descriptor and port.
  // If it fails to resolve the address it will return nil. And if it fails to
  // bind it will return -1.
  // E.g.
  //     var socketAddress = SocketAddress(hostName: "127.0.0.1")
  //     if let br = socketAddress.ip4Bind(fd, port: 9123) {
  //       if br == -1 {
  //         print("Error: Could not start the server. Port may already be " +
  //             "in use by another process.")
  //         exit(1)
  //       }
  //       // Continue the socket setup here. [...]
  //     } else {
  //       print("Error: could not resolve the address.")
  //       let msg = socketAddress.errorMessage ?? ""
  //       print("Error message: \(msg)")
  //       exit(1)
  //     }
  mutating public func ip4Bind(fd: Int32, port: UInt16) -> Int32? {
    if let sa = ip4ToCSocketAddress(port) {
      var address = sa
      let addrlen = UInt32(sizeofValue(address))
      return bind(fd, &address, addrlen)
    }
    return nil
  }

  // When an address cannot be resolved, this will return an error message that
  // could be used to inform the user with.
  public var errorMessage: String? {
    return String.fromCString(gai_strerror(status))
  }

}


public struct Socket {

  var fd: Int32

  public init(fd: Int32) {
    self.fd = fd
  }

  public func write(string: String) -> Int {
    return Sys.writeString(fd, string: string)
  }

  public func writeBytes(bytes: [UInt8], maxBytes: Int) -> Int {
    return Sys.writeBytes(fd, bytes: bytes, maxBytes: maxBytes)
  }

  public func read(inout buffer: [UInt8], maxBytes: Int) -> Int {
    return recv(fd, &buffer, maxBytes, 0)
  }

  public func close() {
    Sys.close(fd)
  }

}


public class ServerSocket {

  var socketAddress: SocketAddress
  var clientAddr = sockaddr_in()
  var clientAddrLen: UInt32 = 0
  var cSocketAddress: CSocketAddress
  var fd: Int32

  public init(hostName: String, port: UInt16) throws {
    clientAddrLen = UInt32(sizeofValue(clientAddr))
    socketAddress = SocketAddress(hostName: hostName)
    fd = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
    if fd == -1 {
      throw ServerSocketError.SocketStart
    }
    if fcntl(fd, F_SETFD, FD_CLOEXEC) == -1 {
      throw ServerSocketError.CloexecSetup
    }
    var v = 1
    if setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &v,
        socklen_t(sizeofValue(v))) == -1 {
      throw ServerSocketError.ReuseAddrSetup
    }
    if let sa = socketAddress.ip4ToCSocketAddress(port) {
      cSocketAddress = sa
      var address = sa
      let addrlen = UInt32(sizeofValue(address))
      if bind(fd, &address, addrlen) == -1 {
        throw ServerSocketError.Bind(message: "Port may be in use by " +
            "another process.")
      }
      listen(fd, SOMAXCONN)
    } else {
      throw ServerSocketError.Address(message:
          socketAddress.errorMessage ?? "")
    }
  }

  public func accept() -> Socket? {
    let fd = rawAccept()
    if fd != -1 {
      return Socket(fd: fd)
    }
    return nil
  }

  func ensureProcessCleanup() {
    var sa = sigaction()
    sigemptyset(&sa.sa_mask)
    sa.sa_flags = SA_NOCLDWAIT
    sigaction(SIGCHLD, &sa, nil)
  }

  public func spawnAccept(fn: (Socket) -> Void) throws {
    ensureProcessCleanup();
    // Create the child process.
    let cfd = rawAccept()
    if cfd == -1 {
      throw ServerSocketError.Accept
    }
    let pid = fork()
    if pid < 0 {
      throw ServerSocketError.Fork
    }
    if pid == 0 {
      // This is the child process.
      defer {
        // Ensure the process exits cleanly.
        exit(0)
      }
      Sys.close(fd)
      fn(Socket(fd: cfd))
    } else {
      Sys.close(cfd)
    }
  }

  // Returns the client file descriptor directly.
  public func rawAccept() -> Int32 {
    return Glibc.accept(fd, &cSocketAddress, &clientAddrLen)
  }

  public func close() {
    Sys.close(fd)
    fd = -1
  }

}


enum ServerSocketError: ErrorType {
  case Address(message: String)
  case Bind(message: String)
  case SocketStart
  case CloexecSetup
  case ReuseAddrSetup
  case Fork
  case Accept
}
