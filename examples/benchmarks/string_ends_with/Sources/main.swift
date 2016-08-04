
import Glibc
import Sua


public extension String {
  public func hasSuffix(_ str: String) -> Bool {
    let count = utf8.count
    let strCount = str.utf8.count
    if count < strCount {
      return false
    }
    for i in 0..<str.utf8.count {
      if utf8[utf8.index(utf8.startIndex, offsetBy: count - i - 1)] !=
          str.utf8[str.utf8.index(str.utf8.startIndex,
              offsetBy: strCount - i - 1)] {
        return false
      }
    }
    return true
  }
}

var sampleCounter = 0
func genSample(_ label: String) -> String {
  sampleCounter += 1
  return "\(label): \(sampleCounter)"
}

let ITERATIONS = 10000

func timeCharacter(_ label: String = "char") {
  var count = 0
  for _ in 0..<ITERATIONS {
    let s = genSample(label)
    let c = s[s.characters.index(s.characters.endIndex, offsetBy: -1)]
    if c == "2" {
      count += 1
    }
  }
  print("timeCharacter (\(label)) count: \(count)")
}

func timeUtf8(_ label: String = "utf8") {
  var count = 0
  let c2 = [UInt8]("2".utf8)[0]
  for _ in 0..<ITERATIONS {
    let s = genSample(label)
    var sa = [UInt8](s.utf8)
    let c = sa[sa.count - 1]
    if c == c2 {
      count += 1
    }
  }
  print("timeUtf8 (\(label)) count: \(count)")
}

func timeHasSuffix(_ label: String = "hsuf") {
  var count = 0
  for _ in 0..<ITERATIONS {
    let s = genSample(label)
    if s.hasSuffix("2") {
      count += 1
    }
  }
  print("timeHasSuffix (\(label)) count: \(count)")
}

func timeTop8(_ label: String = "top8") {
  var count = 0
  let c2 = [UInt8]("2".utf8)[0]
  for _ in 0..<ITERATIONS {
    let s = genSample(label)
    let c = s.utf8[s.utf8.index(s.utf8.startIndex, offsetBy: s.utf8.count - 1)]
    if c == c2 {
      count += 1
    }
  }
  print("timeTop8 (\(label)) count: \(count)")
}

func timeMap8(_ label: String = "map8") {
  var count = 0
  let c2 = [UInt8]("2".utf8)[0]
  for _ in 0..<ITERATIONS {
    let s = genSample(label)
    var sa: [UInt8] = s.utf8.map { $0 }
    let c = sa[sa.count - 1]
    if c == c2 {
      count += 1
    }
  }
  print("timeMap8 (\(label)) count: \(count)")
}

func timeUtf16(_ label: String = "ut16") {
  var count = 0
  let s2 = "2"
  let c2 = s2.utf16[s2.utf16.startIndex]
  for _ in 0..<ITERATIONS {
    let s = genSample(label)
    let c = s.utf16[s.utf16.index(s.utf16.startIndex,
        offsetBy: s.utf16.count - 1)]
    if c == c2 {
      count += 1
    }
  }
  print("timeUtf16 (\(label)) count: \(count)")
}


var utf8Cache = [Int: [UInt8]]()
func prepareUtf8Cache(_ label: String = "ut8c") {
  for i in 0..<ITERATIONS {
    utf8Cache[i] = [UInt8](genSample(label).utf8)
  }
}

func timeUtf8Cache(_ label: String = "ut8c") {
  var count = 0
  let c2 = [UInt8]("2".utf8)[0]
  for i in 0..<ITERATIONS {
    let a = utf8Cache[i]!
    let c = a[a.count - 1]
    if c == c2 {
      count += 1
    }
  }
  print("timeUtf8Cache (\(label)) count: \(count)")
}

func timeEndsWith(_ label: String = "endw") {
  var count = 0
  for _ in 0..<ITERATIONS {
    let s = genSample(label)
    if s.utf16.endsWith("2") {
      count += 1
    }
  }
  print("timeEndsWith (\(label)) count: \(count)")
}

var sw = Stopwatch()
sw.start()
timeCharacter()
print("Elapsed: \(sw.millis)ms")

sw.start()
timeUtf8()
print("Elapsed: \(sw.millis)ms")

sw.start()
timeHasSuffix()
print("Elapsed: \(sw.millis)ms")

sw.start()
timeTop8()
print("Elapsed: \(sw.millis)ms")

sw.start()
timeMap8()
print("Elapsed: \(sw.millis)ms")

sw.start()
timeUtf16()
print("Elapsed: \(sw.millis)ms")

prepareUtf8Cache()
sw.start()
timeUtf8Cache()
print("Elapsed: \(sw.millis)ms")

sw.start()
timeEndsWith()
print("Elapsed: \(sw.millis)ms")
