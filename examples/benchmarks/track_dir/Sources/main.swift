
import Glibc
import Sua
import CSua


var count = 0

func trackDir(pathBytes: [UInt8]) {
  let cap = UnsafePointer<CChar>(pathBytes)
  let dp = opendir(cap)
  if dp == nil {
    // Ignore in case permission denies access to the directory.
    return
  }
  defer {
    closedir(dp)
  }
  var entry = readdir(dp)
  while entry != nil {
    count += 1
    if entry.memory.d_type == 4 {
      var dirName = entry.memory.d_name
      withUnsafePointer(&dirName) { ptr in
        let len = Int(Sys.strlen(UnsafePointer<CChar>(ptr)))
        let b = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(ptr),
            count: len)
        if len <= 2 && b[0] == 46 && (len == 1 || b[1] == 46) {
          // Ignore Dot file: . ..
        } else {
          var cp = [UInt8]()
          cp.reserveCapacity(pathBytes.count + len + 1)
          cp += pathBytes
          cp.removeLast() // Remove null-byte 0
          cp += b
          cp.append(47)
          cp.append(0) // Now append the trailing null-byte 0
          trackDir(cp)
        }
      }
    }
    entry = readdir(dp)
  }
}

func spelunkDir(path: String) {
  let dp = opendir(path)
  if dp == nil {
    // Ignore in case permission denies access to the directory.
    return
  }
  defer {
    closedir(dp)
  }
  var entry = readdir(dp)
  while entry != nil {
    count += 1
    if entry.memory.d_type == 4 {
      var dirName = entry.memory.d_name
      withUnsafePointer(&dirName) { ptr in
        if let name = String.fromCString(UnsafePointer<CChar>(ptr)) {
          if name != "." && name != ".." {
            spelunkDir("\(path)\(name)/")
          }
        }
      }
    }
    entry = readdir(dp)
  }
}

func browseDir(pathBytes: [UInt8]) throws {
  let fb = try FileBrowser(pathBytes: pathBytes)
  while fb.next() {
    count += 1
    if fb.type == .D {
      let nameBytes = fb.nameBytes
      let len = nameBytes.count
      if len <= 2 && nameBytes[0] == 46 && (len == 1 || nameBytes[1] == 46) {
        // Ignore Dot file: . ..
      } else {
        var cp = [UInt8]()
        cp.reserveCapacity(pathBytes.count + nameBytes.count + 1)
        cp += pathBytes
        cp.removeLast() // Remove null-byte 0
        cp += nameBytes
        cp.append(47)
        cp.append(0) // Now append the trailing null-byte 0
        try browseDir(cp)
      }
    }
  }
}

func browseDir2(pathBytes: [UInt8]) throws {
  let fb = try FileBrowser(pathBytes: pathBytes)
  while fb.next() {
    count += 1
    if fb.type == .D {
      var rn = fb.rawEntry.memory.d_name
      try withUnsafePointer(&rn) { ptr in
        let len = Int(Sys.strlen(UnsafePointer<CChar>(ptr)))
        let b = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(ptr),
            count: len)
        if len <= 2 && b[0] == 46 && (len == 1 || b[1] == 46) {
          // Ignore Dot file: . ..
        } else {
          var cp = [UInt8]()
          cp.reserveCapacity(pathBytes.count + len + 1)
          cp += pathBytes
          cp.removeLast() // Remove null-byte 0
          cp += b
          cp.append(47)
          cp.append(0) // Now append the trailing null-byte 0
          try browseDir2(cp)
        }
      }
    }
  }
}

func peekDir(pathBytes: [UInt8]) {
  var pb = pathBytes
  var store = [([UInt8], COpaquePointer)]()
  store.reserveCapacity(128)
  PATH: while store.count >= 0 { // Trick the compiler.
    let cap = UnsafePointer<CChar>(pb)
    var dp = opendir(cap)
    if dp == nil {
      // Ignore in case permission denies access to the directory.
      if store.count > 0 {
        (pb, dp) = store.removeLast()
      } else {
        break PATH
      }
    }
    DIRP: while store.count >= 0 { // Trick the compiler.
      var entry = readdir(dp)
      while entry != nil {
        count += 1
        if entry.memory.d_type == 4 {
          var dirName = entry.memory.d_name
          var ignore = true
          withUnsafePointer(&dirName) { ptr in
            let len = Int(Sys.strlen(UnsafePointer<CChar>(ptr)))
            let b = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(ptr),
                count: len)
            if len <= 2 && b[0] == 46 && (len == 1 || b[1] == 46) {
              // Ignore Dot file: . ..
            } else {
              var cp = [UInt8]()
              cp.reserveCapacity(pb.count + len + 1)
              cp += pb
              cp.removeLast() // Remove null-byte 0
              cp += b
              cp.append(47)
              cp.append(0) // Now append the trailing null-byte 0
              store.append((pb, dp))
              pb = cp
              ignore = false
            }
          }
          if !ignore {
            continue PATH
          }
        }
        entry = readdir(dp)
      }
      closedir(dp)
      if store.count > 0 {
        (pb, dp) = store.removeLast()
        continue DIRP
      } else {
        break PATH
      }
    }
  }
}



var sw = Stopwatch()
var a = [UInt8]("/".utf8)
a.append(0)
sw.start()
trackDir(a)
p("trackDir   count: \(count) Elapsed: \(sw.millis)")

count = 0
sw.start()
spelunkDir("/")
p("spelunkDir count: \(count) Elapsed: \(sw.millis)")

count = 0
sw.start()
do {
  try browseDir(a)
} catch {
  // ignore errors.
}
p("browseDir  count: \(count) Elapsed: \(sw.millis)")

count = 0
sw.start()
do {
  try browseDir2(a)
} catch {
  // ignore errors.
}
p("browseDir2 count: \(count) Elapsed: \(sw.millis)")

count = 0
sw.start()
peekDir(a)
p("peekDir    count: \(count) Elapsed: \(sw.millis)")

count = 0
sw.start()
trackDir(a)
p("**trackDir count: \(count) Elapsed: \(sw.millis)")
