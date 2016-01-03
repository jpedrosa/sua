
import Glibc


func printIP(hostName: String, ip: String?) {
  let z = ip ?? ""
  print("Host: \(hostName), IP: \(z)")
}


func printHostIP(hostName: String) {
  var hints = addrinfo()
  hints.ai_family = AF_INET
  hints.ai_socktype = Int32(SOCK_STREAM.rawValue)
  let flags = AI_ADDRCONFIG
  hints.ai_flags = flags
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
      var sockaddr = h.ai_addr.memory
      withUnsafePointer(&sockaddr) { ptr in
        if fam == AF_INET {
          let sin = UnsafePointer<sockaddr_in>(ptr)
          var sin_addr = sin.memory.sin_addr
          var descBuffer = [CChar](count: Int(len), repeatedValue: 0)
          if inet_ntop(fam, &sin_addr, &descBuffer, UInt32(len)) != nil {
            printIP(hostName, ip: String.fromCString(descBuffer))
          }
        } else {
          var sa = [Int8](count: 1024, repeatedValue: 0)
          if getnameinfo(&info.memory.ai_addr.memory,
              UInt32(sizeof(sockaddr_in6)), &sa, 1024, nil, 0, flags) == 0 {
            printIP(hostName, ip: String.fromCString(sa))
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
