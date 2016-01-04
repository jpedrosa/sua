
import Glibc
import CSua
import Sua


func printHostIP(hostName: String) {
  var sa = SocketAddress(hostName: hostName)
  if let s = sa.ip6ToString() {
    print("Host: \(hostName), IP: \(s)")
  } else {
    print("Error: couldn't find address for \"\(hostName)\".")
    let msg = sa.errorMessage ?? ""
    print("Error message: \(msg)")
  }
}


var addressName = "google.com"
printHostIP(addressName)
printHostIP("reddit.com")

var sa = SocketAddress(hostName: addressName)
p(sa.ip4ToUInt32())
p(sa.ip4ToString())
p(sa.ip6ToString())
printList(sa.ip4ToStringList() ?? [])


var count = 0
var sw = Stopwatch()
sw.start()
for _ in 0..<1000 {
  var sample = "GET / HTTP/1.1\r\nHost: 127.0.0.1:9123\r\nUser-Agent: curl/7.43.0\r\nAccept: */*\r\n\r\n"
  var a = [UInt8](sample.utf8)
  var parser = HeaderParser()
  try parser.parse(a)
  if parser.header.method == "GET" {
    count += 1
  }
//  p(parser)
}
p("Count \(count) Elapsed: \(sw.millis)")


let serverSocket = try ServerSocket(hostName: "127.0.0.1", port: 9123)

defer {
  serverSocket.close()
}

var buffer = [UInt8](count: 1024, repeatedValue: 0)

while true {
  if let socket = serverSocket.accept() {
    defer {
      socket.close()
    }
    var n = socket.read(&buffer, maxBytes: buffer.count)
    socket.write("Hello World\n")
  }
}
