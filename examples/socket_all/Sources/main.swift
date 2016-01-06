
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


func printUsage() {
  print("SocketAll: SocketAll -type (s|t|f) [-port #]\n" +
      "Usage: run SocketAll by giving it at least the type parameter.\n" +
      "    -type s | t | f        s for single; t for threaded; f for forked.\n" +
      "    -port 9123             port, which defaults to 9123. Range from 0 to" +
                              " 65535.\n" +
      "E.g.\n" +
      "    > SocketAll -type s\n" +
      "    > SocketAll -type s -port 9123\n")
}

func processArguments() -> SocketAllOptions? {
  let args = Process.arguments
  var i = 1
  let len = args.count
  var stream = CodeUnitStream()
  var type: SocketAllType?
  var port: UInt16?
  func error(ti: Int = -1) {
    type = nil
    let t = args[ti < 0 ? i : ti]
    print("\u{1b}[1m\u{1b}[31mError:\u{1b}[0m Error while parsing the " +
        "command-line options: ^\(t)\n")
    printUsage()
  }
  func eatPortDigits() -> Bool {
    if stream.eatWhileDigit() {
      let s = stream.collectTokenString()
      stream.eatSpace()
      if stream.isEol {
        let n = Int(s!)!
        if n >= 0 && n <= 65535 {
          port = UInt16(n)
          return true
        }
      }
    }
    return false
  }
  while i < len {
    switch args[i] {
      case "-type":
        i += 1
        if i < len {
          switch args[i] {
            case "s":
              type = .Single
            case "t":
              type = .Threaded
            case "f":
              type = .Forked
            default:
              error()
              break
          }
        } else {
          error(i - 1)
          break
        }
      case "-types":
        type = .Single
      case "-typet":
        type = .Threaded
      case "-typef":
        type = .Forked
      case "-port":
        i += 1
        if i < len {
          stream.codeUnits = Array(args[i].utf8)
          if !eatPortDigits() {
            error()
            break
          }
        } else {
          error(i - 1)
          break
        }
      default:
        stream.codeUnits = Array(args[i].utf8)
        if stream.eatString("-port") {
          stream.startIndex = stream.currentIndex
          if !eatPortDigits() {
            error()
            break
          }
        } else {
          error()
          break
        }
    }
    i += 1
  }
  if type != nil {
    var o = SocketAllOptions()
    o.type = type!
    if port != nil {
      o.port = port!
    }
    return o
  }
  if len == 1 {
    printUsage()
  }
  return nil
}


if let opt = processArguments() {
  print("Starting the server on \(opt.hostName):\(opt.port)")
  var sa = try SocketAll(hostName: opt.hostName, port: opt.port)
  switch opt.type {
    case .Single:
      print("Server type: Single. Single process, single thread.")
      sa.runSingle()
    case .Threaded:
      print("Server type: Threaded. Multiple threads on a single process.")
      try sa.runThreaded()
    case .Forked:
      print("Server type: Forked. Multiple forked processes with single " +
          "thread.")
      try sa.runForked()
  }
}
