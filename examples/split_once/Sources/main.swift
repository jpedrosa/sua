
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

extension String.UTF16View {

  private func splitOnceFB2(at: String.UTF16View)
    -> (String.UTF16View, String.UTF16View)? {
      guard let c = at.first else { return nil }
      let second = at.startIndex.successor()
      for i in startIndex..<endIndex.advancedBy(1-at.count) where self[i] == c {
        var (j,k) = (second,i.successor())
        repeat {
          if j == at.endIndex {
            return (prefixUpTo(i), suffixFrom(k))
          } else if k == endIndex {
            break
          }
        } while self[k++] == at[j++]
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

  public func splitOnceFB2(string: String) -> (String, String)? {
    return self
      .utf16
      .splitOnceFB2(string.utf16)
      .map { (a,b) in (String(a), String(b)) }
  }

}

let ITERATIONS = 10000
let sample = "abcdefghijklmnopqrstuvxywz"
let sw = Stopwatch()
var count = 0

p("String#splitOnceFB")
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

count = 0
p("String#splitOnceFB2")
sw.start()
for _ in 0..<ITERATIONS {
  let (key, value) = sample.splitOnceFB2("kl")!
  if !key.isEmpty {
    count += 1
  }
}
p("Elapsed: \(sw.millis)ms count: \(count)")
