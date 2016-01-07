
import Glibc


public class Mutex {

  var id = pthread_mutex_t()

  public init() {
    pthread_mutex_init(&id, nil)
  }

  public func lock() {
    pthread_mutex_lock(&id)
  }

  public func unlock() {
    pthread_mutex_unlock(&id)
  }

}


var registerThreadMutex = Mutex()
var threadCallbacks: [pthread_t: () -> Void] = [:]

func runPthread(ctx: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> {
  let id = pthread_self()
  defer {
    threadCallbacks[id] = nil
  }
  var fn = threadCallbacks[id]
  while fn == nil {
    // Yield to parent thread so it can set up the callback for us.
    IO.sleep(0.000000001)
    fn = threadCallbacks[id]
  }
  fn!()
  return ctx
}

func createPthread(inout id: UInt, fn: () -> Void) {
  registerThreadMutex.lock()
  defer {
    registerThreadMutex.unlock()
  }
  pthread_create(&id, nil, runPthread, nil)
  threadCallbacks[id] = fn
}


// This class enables pthreads with a handy syntax.
// E.g.
//     let serverSocket = try ServerSocket(hostName: "127.0.0.1", port: 9123)
//     defer {
//       serverSocket.close()
//     }
//     var buffer = [UInt8](count: 1024, repeatedValue: 0)
//     while true {
//       if let socket = serverSocket.accept() {
//         var tb = Thread() {
//           defer {
//             socket.close()
//           }
//           var n = socket.read(&buffer, maxBytes: buffer.count)
//           socket.write("Hello World\n")
//         }
//         try tb.join()
//       }
//     }
public class Thread {

  public var threadId = pthread_t()

  // Just a default initializer. Callback can be passed by a later call to #run
  public init() { }

  public init(fn: () -> Void) {
    run(fn)
  }

  public func run(fn: () -> Void) {
    createPthread(&threadId, fn: fn)
  }

  // On the importance of calling join to help to avoid memory leaks, see this
  // SO thread: http://stackoverflow.com/questions/17642433/why-pthread-causes-a-memory-leak
  public func join() throws -> Thread {
    if pthread_join(threadId, nil) != 0 {
      throw ThreadError.Join
    }
    return self
  }

  public func detach() throws -> Thread {
    if pthread_detach(threadId) != 0 {
      throw ThreadError.Detach
    }
    return self
  }

}


public enum ThreadError: ErrorType {
  case Detach
  case Join
}
