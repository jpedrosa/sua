
import Glibc
import CSua
import Sua


let serverSocket = try ServerSocket(hostName: "127.0.0.1", port: 9123)

defer {
  serverSocket.close()
}

//var buffer = [UInt8](repeating: 0, count: 1024)

// while true {
//   try serverSocket.spawnAccept() { socket in
//     defer {
//       socket.close()
//     }
//     var n = socket.read(buffer: &buffer, maxBytes: buffer.count)
//     socket.write("Hello World\n")
//   }
// }

var socketMutex = Mutex()

func runSocket(ctx: UnsafeMutablePointer<Void>?)
    -> UnsafeMutablePointer<Void>? {
  if let ectx = ctx {
    pthread_detach(pthread_self())
    socketMutex.lock()
    let socket = UnsafePointer<Socket>(ectx).pointee
    defer {
      socket.close()
      socketMutex.unlock()
    }
    var b = [UInt8](repeating: 0, count: 1024)
    let _ = socket.read(buffer: &b, maxBytes: b.count)
    let _ = socket.write(string: "Hello World\n")
  }
  return ctx
}


while true {
  if let socket = serverSocket.accept() {
    var id = pthread_t()
    var s = socket
    pthread_create(&id, nil, runSocket, &s)
  }
}

// while true {
//   if let socket = serverSocket.accept() {
//     var tb = Thread() {
//       defer {
//         socket.close()
//       }
//       var buffer = [UInt8](repeating: 0, count: 1024)
//       var n = socket.read(buffer: &buffer, maxBytes: buffer.count)
//       socket.write("Hello World\n")
//     }
// //    try tb.join()
//     try tb.detach()
//   }
// }

// while true {
//   if let socket = serverSocket.accept() {
//     defer {
//       socket.close()
//     }
//     let _ = socket.read(buffer: &buffer, maxBytes: buffer.count)
//     socket.write("Hello World\n")
//   }
// }
