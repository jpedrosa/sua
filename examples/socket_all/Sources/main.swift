
import Glibc
import CSua
import Sua


class SocketAll {

  let serverSocket: ServerSocket

  var buffer = [UInt8](count: 1024, repeatedValue: 0)

  init(hostName: String, port: UInt16) throws {
    serverSocket = try ServerSocket(hostName: hostName, port: port)
  }

  func close() {
    serverSocket.close()
  }

  func runThreaded() throws {
    while true {
      if let socket = serverSocket.accept() {
        var tb = Thread() {
          defer {
            socket.close()
          }
          var buffer = [UInt8](count: 1024, repeatedValue: 0)
          var _ = socket.read(&buffer, maxBytes: buffer.count)
          socket.write("Hello World\n")
        }
        try tb.join()
      }
    }
  }

  func runForked() throws {
    while true {
      try serverSocket.spawnAccept() { socket in
        self.answer(socket)
      }
    }
  }

  func runSingle() {
    while true {
      if let socket = serverSocket.accept() {
        answer(socket)
      }
    }
  }

  func answer(socket: Socket) {
    defer {
      socket.close()
    }
    let _ = socket.read(&buffer, maxBytes: buffer.count)
    socket.write("Hello World\n")
  }

}


enum SocketAllType {
  case Single
  case Threaded
  case Forked
}


struct SocketAllOptions {

  var port: UInt16 = 9123
  var hostName = "127.0.0.1"
  var type: SocketAllType = .Single

}


func processArguments() -> SocketAllOptions? {
  return nil
}


if let opt = processArguments() {
  var sa = try SocketAll(hostName: opt.hostName, port: opt.port)
  switch opt.type {
    case .Single:
      sa.runSingle()
    case .Threaded:
      try sa.runThreaded()
    case .Forked:
      try sa.runForked()
  }
} else {
  print("SocketAll: SocketAll -type (s|t|f) [-port #]\n" +
      "Usage: run SocketAll by giving it at least the type parameter.\n" +
      "-type s | t | f        s for single; t for threaded; f for forked.\n" +
      "-port 9123             port, which defaults to 9123.\n" +
      "E.g.\n" +
      "> SocketAll -type s\n" +
      "> SocketAll -type s -port 9123\n")
}
