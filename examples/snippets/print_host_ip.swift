
import Glibc


func printIP(_ hostName: String, ip: String?) {
  let z = ip ?? ""
  print("Host: \(hostName), IP: \(z)")
}


func printHostIP(_ hostName: String) {
  var hints = addrinfo()
  hints.ai_family = AF_INET
  hints.ai_socktype = Int32(SOCK_STREAM.rawValue)
  let flags = AI_ADDRCONFIG
  hints.ai_flags = flags
  hints.ai_protocol = Int32(IPPROTO_TCP)
  var info = UnsafeMutablePointer<addrinfo>(nil)
  let status = getaddrinfo(hostName, nil, &hints, &info)
  defer {
    freeaddrinfo(info)
  }
  if let einfo = info {
    if status == 0 {
      var h = einfo.pointee
      while true {
        let fam = h.ai_family
        let len = fam == AF_INET ? INET_ADDRSTRLEN : INET6_ADDRSTRLEN
        var sockaddr = h.ai_addr.pointee
        withUnsafePointer(&sockaddr) { ptr in
          if fam == AF_INET {
            let sin = UnsafePointer<sockaddr_in>(ptr)
            var sin_addr = sin.pointee.sin_addr
            var descBuffer = [CChar](repeating: 0, count: Int(len))
            if inet_ntop(fam, &sin_addr, &descBuffer, UInt32(len)) != nil {
              printIP(hostName, ip: String(cString: descBuffer))
            }
          } else {
            var sa = [Int8](repeating: 0, count: 1024)
            if getnameinfo(&einfo.pointee.ai_addr.pointee,
                UInt32(sizeof(sockaddr_in6.self)),
                &sa, 1024, nil, 0, flags) == 0 {
              printIP(hostName, ip: String(cString: sa))
            }
          }
        }

        if let next = h.ai_next {
          h = next.pointee
        } else {
          break
        }
      }
      return
    }
  }
  print("Error: couldn't find address for \"\(hostName)\").")
  let msg = String(cString: gai_strerror(status)) ?? ""
  print("Error message: \(msg)")
}

printHostIP("google.com")
printHostIP("reddit.com")
