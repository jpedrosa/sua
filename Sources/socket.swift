
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
  //     address.sin_addr.s_addr = sa.ip4ToString()
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
      address.sin_port = ByteOrder.htons(port)
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
  // could be used to inform the user.
  public var errorMessage: String? {
    return String.fromCString(gai_strerror(status))
  }

}
