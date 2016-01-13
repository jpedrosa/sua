
import Glibc
import Sua
import CSua

var sw = Stopwatch()

var rng = RNG()
let NI = 30

sw.start()
for _ in 0..<NI {
  p(rng.nextInt(10))
}
p("It took \(sw.millis)ms to generate these \(NI) random ints.")

let ND = 30

sw.start()
for _ in 0..<ND {
  p(rng.nextDouble())
}
p("It took \(sw.millis)ms to generate these \(ND) random doubles.")

var m = [String: String]()

sw.start()
var filesCount = 0
FileBrowser.recurseDir("/home/dewd/t_") { (name, type, path) in
  if type == .F {
    filesCount += 1
    var fp = "\(path)\(name)"
    try! File.open(fp) { f in
      do {
        var a = try f.readAllBytes()
        m[fp] = String(MurmurHash3.hash32Bytes(a, maxBytes: a.count))
      } catch {
        p("(failed to read file: \(fp))")
      }
    }
  }
}
p("It took \(sw.millis)ms to hash the \(filesCount) files in these directories.")

var i = 0
for (k, v) in m {
  p("\(k): \(v)")
  if i > 10 {
    break
  }
  i += 1
}

print("Starting stopwatch again...")

sw.start()
sleep(1)
sw.stop()
print("Elapsed: \(sw.millis)")
sw.start()
sleep(2)
print("Elapsed: \(sw.millis)")
sleep(3)
print("Elapsed: \(sw.millis)")
