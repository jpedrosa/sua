
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
var registerThreadCallback: (() -> Void)?

func runPthread(ctx: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> {
  registerThreadCallback!()
  return ctx
}

func createPthread(inout id: UInt, fn: () -> Void) {
  registerThreadMutex.lock()
  registerThreadCallback = fn
  defer {
    registerThreadMutex.unlock()
  }
  pthread_create(&id, nil, runPthread, nil)
}


public class Thread {

  public var threadId = pthread_t()

  // Just a default initializer. Callback can be passed by a later call to #run
  init() { }

  init(fn: () -> Void) {
    run(fn)
  }

  public func run(fn: () -> Void) {
    createPthread(&threadId, fn: fn)
  }

  public func join() {
    pthread_join(threadId, nil)
  }

}
