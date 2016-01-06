ServerSocket
------------

It used to be that TCP was not the only game in town. But then the web took over
and nowadays it's the standard. It means that when writing new socket libraries,
we don't even need to prefix them with TCP like in the old days. We can name
them just ServerSocket, Socket and that is it!

A ServerSocket is the building block that web frameworks and servers start from.
Building on it come the HTTP header parsers and higher level libraries.

I've come up with a new [ServerSocket](../Sources/socket.swift) class that does a
handful of things. It has support for single process server but also comes with
support for forking processes for a multiple process server. And if threading is
what we need, I've also come up with a [Thread](../Sources/thread.swift) class that
makes it easy to upgrade the single process server to a multi-threaded server.

Here are some basic examples of each one of them:

```swift
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
    let _ = socket.read(&buffer, maxBytes: buffer.count)
    socket.write("Hello World\n")
  }
}
```

That's the basic single process, single thread example. It still performs great
at handling just a "Hello World" kind of load, as we'll see later in the
benchmark.

Note: As someone on Reddit reminded me, in Swift apparently we don't need to
call defer all the time as the Swift runtime can do that for us at a somewhat
predictable time. I think it's up to the application to decide. As a library
author I am more inclined to keep it in the code, even in a sample code.

Now for the multi-threaded version of it:

```swift
let serverSocket = try ServerSocket(hostName: "127.0.0.1", port: 9123)

defer {
  serverSocket.close()
}

var buffer = [UInt8](count: 1024, repeatedValue: 0)

while true {
  if let socket = serverSocket.accept() {
    var tb = Thread() {
      defer {
        socket.close()
      }
      var n = socket.read(&buffer, maxBytes: buffer.count)
      socket.write("Hello World\n")
    }
    try tb.join()
  }
}
```

It only changed from the first version in a couple of extra lines and an extra
indentation level for the thread callback. The thread needs the call to "join"
so that the resources allocated to the thread can be reclaimed by the pthread
C library, otherwise it would quickly leak a ton of memory.

Even in Ruby I recall that one of the first web servers we created with it used
this kind of multi-threaded approach. And before that we also did it in Java,
Delphi and so on. The difference from some other languages to Swift is that
Swift's thread are native by default. It means that they are real threads and
not some green thread used for concurrency only. It also means that you need to
be careful as a user of it to be sure that the code that you use is thread safe,
otherwise you could get some unpredictable errors at runtime.

And that's my beef with threads. I don't want to be the guarantor who makes
sure that all code that is thrown at it will be thread safe by default. I would
rather preach the next version based on forking of processes, since then
everything would only have 1 thread for us to worry about:

```swift
let serverSocket = try ServerSocket(hostName: "127.0.0.1", port: 9123)

defer {
  serverSocket.close()
}

var buffer = [UInt8](count: 1024, repeatedValue: 0)

while true {
  try serverSocket.spawnAccept() { socket in
    defer {
      socket.close()
    }
    var n = socket.read(&buffer, maxBytes: buffer.count)
    socket.write("Hello World\n")
  }
}
```

Since the forking is supported by the library by default, we get as clean a code
as the examples just before it, even though the actual code is slightly more
involved.

While forking the processes, the child process has to close the file descriptor
coming from the parent process. And the parent process has to close the file
descriptor of the child process it just birthed. And when it's all done and the
child process has finished executing, the OS needs to
[collect](http://stackoverflow.com/questions/6718272/c-exec-fork-defunct-processes)
the "defunct" processes from its table access.

The benchmark tells us for the simple "Hello World" example:

*Server type: Single. Single process, single thread.*
```
$ .build/release/SocketAll -type s
Starting the server on 127.0.0.1:9123
Server type: Single. Single process, single thread.

$ ab -n 10000 -c 50 http://127.0.0.1:9123/
[...]
Concurrency Level:      50
Time taken for tests:   0.343 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      120000 bytes
HTML transferred:       0 bytes
Requests per second:    29121.41 [#/sec] (mean)
Time per request:       1.717 [ms] (mean)
Time per request:       0.034 [ms] (mean, across all concurrent requests)
Transfer rate:          341.27 [Kbytes/sec] received
[...]
```

*Server type: Threaded. Multiple threads on a single process.*
```
$ .build/release/SocketAll -type t
Starting the server on 127.0.0.1:9123
Server type: Threaded. Multiple threads on a single process.

$ ab -n 10000 -c 50 http://127.0.0.1:9123/
[...]
Concurrency Level:      50
Time taken for tests:   0.390 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      120000 bytes
HTML transferred:       0 bytes
Requests per second:    25632.42 [#/sec] (mean)
Time per request:       1.951 [ms] (mean)
Time per request:       0.039 [ms] (mean, across all concurrent requests)
Transfer rate:          300.38 [Kbytes/sec] received
[...]
```

*Server type: Forked. Multiple forked processes with single thread.*
```
$ .build/release/SocketAll -type f
Starting the server on 127.0.0.1:9123
Server type: Forked. Multiple forked processes with single thread.

$ ab -n 10000 -c 50 http://127.0.0.1:9123/
[...]
Concurrency Level:      50
Time taken for tests:   1.238 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      120000 bytes
HTML transferred:       0 bytes
Requests per second:    8074.37 [#/sec] (mean)
Time per request:       6.192 [ms] (mean)
Time per request:       0.124 [ms] (mean, across all concurrent requests)
Transfer rate:          94.62 [Kbytes/sec] received
[...]
```

While forking the processes, it is relatively slower. But consider that with
forking processes we don't have to worry about multiple threads and we could be
able to use C code that is not meant to be thread safe, say in graphic libraries
that you want to use or any other kind of library for that matter. Scripting
languages often have a Global Interpreter Lock that makes them single threaded
for the most part, but it enables them to access C library code that is not
thread safe and it also gives them some peace of mind regarding having to deal
with multiple threads.

Other alternatives like async programming can also be used. Async programming is
very popular at the moment with Node.JS. While Async programming is cool, it can
change the way that algorithms are written. APIs start labeling their content by
adding a suffix like "Sync", "Async". Libraries change by making the callbacks
more standardized by means of Promise or Future. And later on async/await if
your project has the resources to do it. And this all helps with having a single
process potentially handling a greater work-load while sharing the memory in the
process.

I don't have plans to start on that path for Async. And we'll see when Swift
gets its coherent concurrency in a future release, potentially in 2017.

For now, I am more worried about the compilation time of depending on an
external library. While programming the following
[example](../examples/socket_all/Sources/main.swift)
that I used to create
the benchmark with, I noticed that the compilation time started to grow into
many seconds, that my eyes started to wander to other windows in the other
display. When developing inside the main library I don't have a problem with
the compilation time yet. So it could be that the problem is caused by the
package manager itself. To mitigate it, we could "inline" the library code
inside our project code. Perhaps that's how it works like in Apple's Xcode. As
the package manager is relatively experimental and in its early days, let's hope
that it will improve in the future.

```swift

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
```

I like the way that Swift code looks! :-)

The inspiration for the forking process server came from my experimentation with
a new runtime for Dart called Fletch. Fletch does a couple more things by using
1 native thread per core and has some message passing support.
