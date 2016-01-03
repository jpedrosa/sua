
import Glibc


func printIP(hostName: String, buffer: [CChar]) {
  let z = String.fromCString(buffer) ?? ""
  print("Host: \(hostName), IP: \(z)")
}

func printHostIP(hostName: String) {
  var hints = addrinfo()
  hints.ai_family = AF_INET
  hints.ai_socktype = Int32(SOCK_STREAM.rawValue)
  hints.ai_flags = AI_ADDRCONFIG
  hints.ai_protocol = Int32(IPPROTO_TCP)
  var info = UnsafeMutablePointer<addrinfo>()
  let status = getaddrinfo(hostName, nil, &hints, &info)
  defer {
    freeaddrinfo(info)
  }
  if status == 0 {
    var h = info.memory
    while true {
      let fam = h.ai_family
      let len = fam == AF_INET ? INET_ADDRSTRLEN : INET6_ADDRSTRLEN
      var descBuffer = [CChar](count: Int(len), repeatedValue: 0)
      var sockaddr = h.ai_addr.memory
      withUnsafePointer(&sockaddr) { ptr in
        if fam == AF_INET {
          let sin = UnsafePointer<sockaddr_in>(ptr)
          var sin_addr = sin.memory.sin_addr
          if inet_ntop(fam, &sin_addr, &descBuffer, UInt32(len)) != nil {
            printIP(hostName, buffer: descBuffer)
          }
        } else {
          let sin = UnsafePointer<sockaddr_in6>(ptr)
          var sin_addr = sin.memory.sin6_addr
          if inet_ntop(fam, &sin_addr, &descBuffer, UInt32(len)) != nil {
            printIP(hostName, buffer: descBuffer)
          }
        }
      }
      let next = h.ai_next
      if next == nil {
        break
      } else {
        h = next.memory
      }
    }
  } else {
    print("Error: couldn't find address for \"\(hostName)\").")
    let msg = String.fromCString(gai_strerror(status)) ?? ""
    print("Error message: \(msg)")
  }
}

printHostIP("google.com")
printHostIP("reddit.com")
