
import Glibc
import CSua
import Sua


var network: [String?] = []
var networkMutex = Mutex()

var tClient = Thread() {
  while true {
    let s = readLine()
    networkMutex.lock()
    defer { networkMutex.unlock() }
    network.append(s)
  }
}

var tServer = Thread() {
  while true {
    IO.sleep(1)
    networkMutex.lock()
    defer { networkMutex.unlock() }
    if !network.isEmpty {
      if let s = network.removeFirst() {
        let z = s ?? ""
        print("server: \(z)")
      }
    }
  }
}

try tClient.join()
