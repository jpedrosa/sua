

enum ByteMatcherEntry {
  case EatWhileDigit
  case Next
  case SkipToEnd
  case EatOne
  case EatUntilOne
  case EatBytes
  case EatUntilBytes
  case EatUntilIncludingBytes
  case MatchEos
}


protocol ByteMatcherEntryData {
  var entry: ByteMatcherEntry { get }
  var optional: Bool { get }
}


struct ByteMatcher {


  struct EmptyParams: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
    var optional: Bool
  }


  struct UInt8Param: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
    var optional: Bool
    var c: UInt8
  }


  struct BytesParam: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
    var optional: Bool
    var bytes: [UInt8]
  }


  var stream = ByteStream()
  var list = [ByteMatcherEntryData]()
  var _retryAware = false
  var _retryAtPartialSuccess = false

  mutating func match(string: String) -> Int {
    return matchAt(string, startIndex: 0)
  }

  // Returns the length of the match, the difference between the last matched
  // index + 1 and the startIndex.
  //
  // Returns -1 in case the matching was unsuccessful.
  mutating func matchAt(string: String, startIndex: Int) -> Int {
    var b = false
    stream.bytes = string.bytes
    stream.startIndex = startIndex
    stream.currentIndex = startIndex
    if _retryAware {
      _retryAtPartialSuccess = false
      // b = doMatchWithRetry()
    } else {
      b = doMatch()
    }
    if b {
      return stream.currentIndex - startIndex
    }
    return -1
  }

  mutating func doMatch() -> Bool {
    for data in list {
      var b = false
      switch data.entry {
        case .EatWhileDigit:
          b = stream.eatWhileDigit()
        case .SkipToEnd:
          b = stream.skipToEnd()
        case .MatchEos:
          b = stream.currentIndex >= stream.bytes.count
        case .Next:
          b = stream.next() != nil
        case .EatOne:
          let c = (data as! UInt8Param).c
          b = stream.eatOne(c)
        case .EatUntilOne:
          let c = (data as! UInt8Param).c
          b = stream.eatUntilOne(c)
        case .EatBytes:
          let bytes = (data as! BytesParam).bytes
          b = stream.eatBytes(bytes)
        case .EatUntilBytes:
          let bytes = (data as! BytesParam).bytes
          b = stream.eatUntilBytes(bytes)
        case .EatUntilIncludingBytes:
          let bytes = (data as! BytesParam).bytes
          b = stream.eatUntilIncludingBytes(bytes)
      }
      if !b && !data.optional { // No success and not optional.
        return false
      }
    }
    return true
  }

  mutating func add(entry: ByteMatcherEntry, optional: Bool) {
    list.append(EmptyParams(entry: entry, optional: optional))
  }

  mutating func eatWhileDigit(optional: Bool = false) {
    add(.EatWhileDigit, optional: optional)
  }

  mutating func next(optional: Bool = false) {
    add(.Next, optional: optional)
  }

  mutating func skipToEnd() {
    add(.SkipToEnd, optional: false)
  }

  mutating func matchEos() {
    add(.MatchEos, optional: false)
  }

  mutating func eatOne(c: UInt8, optional: Bool = false) {
    list.append(UInt8Param(entry: .EatOne, optional: optional, c: c))
  }

  mutating func eatUntilOne(c: UInt8, optional: Bool = false) {
    list.append(UInt8Param(entry: .EatUntilOne, optional: optional, c: c))
  }

  mutating func eatString(string: String, optional: Bool = false) {
    eatBytes(string.bytes, optional: optional)
  }

  mutating func eatBytes(bytes: [UInt8], optional: Bool = false) {
    list.append(BytesParam(entry: .EatBytes, optional: optional, bytes: bytes))
  }

  mutating func eatUntilString(string: String, optional: Bool = false) {
    eatUntilBytes(string.bytes)
  }

  mutating func eatUntilBytes(bytes: [UInt8], optional: Bool = false) {
    list.append(BytesParam(entry: .EatUntilBytes, optional: optional,
        bytes: bytes))
  }

  mutating func eatUntilIncludingString(string: String,
      optional: Bool = false) {
    eatUntilIncludingBytes(string.bytes)
  }

  mutating func eatUntilIncludingBytes(bytes: [UInt8], optional: Bool = false) {
    list.append(BytesParam(entry: .EatUntilIncludingBytes, optional: optional,
        bytes: bytes))
  }

}
