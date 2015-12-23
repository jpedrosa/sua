
import Glibc
import Sua


extension String.CharacterView {

  func splitOnceFB(at: String.CharacterView)
    -> (String.CharacterView, String.CharacterView)? {
      for i in indices {
        var g = at.generate()
        for j in i..<endIndex {
          guard let c = g.next() else {
            return (prefixUpTo(i), suffixFrom(j))
          }
          if self[j] != c { break }
        }
      }
      return nil
  }

}

extension String {

  func splitOnceFB(at: String) -> (String, String)? {
    return self
      .characters
      .splitOnceFB(at.characters)
      .map { (a,b) in (String(a), String(b)) }
  }

}

let ITERATIONS = 10000
let sample = "abcdefghijklmnopqrstuvxywz"
let sw = Stopwatch()
var count = 0

p("splitOnceFB#splitOnceFB")
sw.start()
for _ in 0..<ITERATIONS {
  let (key, value) = sample.splitOnceFB("kl")!
  if !key.isEmpty {
    count += 1
  }
}
p("Elapsed: \(sw.millis)ms count: \(count)")

count = 0
p("String.CharacterView#splitOnceFB")
sw.start()
for _ in 0..<ITERATIONS {
  let (key, value) = sample.characters.splitOnceFB("kl".characters)!
  if !key.isEmpty {
    count += 1
  }
}
p("Elapsed: \(sw.millis)ms count: \(count)")

count = 0
p("String.#splitOnce")
sw.start()
for _ in 0..<ITERATIONS {
  let (key, value) = sample.splitOnce("kl")
  if !key!.isEmpty {
    count += 1
  }
}
p("Elapsed: \(sw.millis)ms count: \(count)")
