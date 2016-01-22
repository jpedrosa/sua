

public typealias FirstCharTable = [[[UInt8]]?]

public let FirstCharTableValue = [[UInt8]]()


public struct ByteStream {

  public var _bytes: [UInt8] = []
  public var startIndex = 0
  public var currentIndex = 0
  public var lineEndIndex = 0
  public var milestoneIndex = 0

  public init(bytes: [UInt8] = [], startIndex: Int = 0,
      lineEndIndex: Int = 0) {
    self.startIndex = startIndex
    self.lineEndIndex = lineEndIndex
    _bytes = bytes
    currentIndex = startIndex
    if lineEndIndex == 0 {
      self.lineEndIndex = bytes.count
    }
  }

  public var bytes: [UInt8] {
    get { return _bytes }
    set {
      _bytes = newValue
      currentIndex = 0
      startIndex = 0
      lineEndIndex = newValue.count
    }
  }

  public mutating func reset() {
    currentIndex = 0
    startIndex = 0
    lineEndIndex = _bytes.count
  }

  public var isEol: Bool { return currentIndex >= lineEndIndex }

  public var current: UInt8 { return _bytes[currentIndex] }

  public func peek() -> UInt8? {
    return currentIndex < lineEndIndex ? _bytes[currentIndex] : nil
  }

  public mutating func next() -> UInt8? {
    var r: UInt8?
    if currentIndex < lineEndIndex {
      r = _bytes[currentIndex]
      currentIndex += 1
    }
    return r
  }

  public mutating func eat(fn: (c: UInt8) -> Bool) -> Bool {
    return match(true, fn: fn)
  }

  public mutating func match(consume: Bool = false, fn: (c: UInt8) -> Bool)
      -> Bool {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i]
      if fn(c: c) {
        if consume {
          currentIndex = i + 1
        }
        return true
      }
    }
    return false
  }

  public mutating func eatOne(c: UInt8) -> Bool {
    return matchOne(c, consume: true)
  }

  public mutating func matchOne(c: UInt8, consume: Bool = false) -> Bool {
    let i = currentIndex
    if i < lineEndIndex && c == _bytes[i] {
      if consume {
        currentIndex = i + 1
      }
      return true
    }
    return false
  }

  public mutating func eatWhileOne(c: UInt8) -> Bool {
    return matchWhileOne(c, consume: true) >= 0
  }

  public mutating func matchWhileOne(c: UInt8, consume: Bool = false) -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      if c != _bytes[i] {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatSpace() -> Bool {
    return matchSpace(true) >= 0
  }

  public mutating func eatWhileSpace() -> Bool {
    return matchWhileSpace(true) >= 0
  }

  public mutating func matchSpace(consume: Bool = false) -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i]
      if c == 32 || c == 160 { // space or \u00a0
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func matchWhileSpace(consume: Bool = false) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    while i < len {
      let c = _bytes[i]
      if c != 32 && c != 160 {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatSpaceTab() -> Bool {
    return matchSpaceTab(true) != nil
  }

  public mutating func eatWhileSpaceTab() -> Bool {
    return matchWhileSpaceTab(true) >= 0
  }

  public mutating func matchSpaceTab(consume: Bool = false) -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i]
      if c == 32 || c == 160 || c == 9 { // space or \u00a0 or tab
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func matchWhileSpaceTab(consume: Bool = false) -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _bytes[i]
      if c != 32 && c != 160 && c != 9 { // space or \u00a0 or tab
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func skipToEnd() -> Bool {
    currentIndex = lineEndIndex
    return true
  }

  public func findIndex(c: UInt8, startAt: Int = 0) -> Int {
    let len = _bytes.count
    let lim = len - 2
    var i = startAt
    while i < lim {
      if _bytes[i] == c || _bytes[i + 1] == c ||
          _bytes[i + 2] == c {
        break
      }
      i += 3
    }
    while i < len {
      if _bytes[i] == c {
        return i
      }
      i += 1
    }
    return -1
  }

  public mutating func skipTo(c: UInt8) -> Int {
    let r = findIndex(c, startAt: currentIndex)
    if r >= startIndex && r < lineEndIndex {
      currentIndex = r
    }
    return r
  }

  public mutating func backUp(n: Int) {
    currentIndex -= n
  }

  public mutating func keepMilestoneIfNot(fn: () -> Bool) -> Bool {
    let r = fn()
    if !r {
      milestoneIndex = currentIndex + 1
    }
    return r
  }

  public mutating func yankMilestoneIfNot(fn: () -> Bool) -> Bool {
    if !fn() {
      milestoneIndex = currentIndex + 1
    }
    return false
  }

  public mutating func eatUntil(fn: (c: UInt8) -> Bool) -> Bool {
    return matchUntil(true, fn: fn) >= 0
  }

  public mutating func matchUntil(consume: Bool = false, fn: (c: UInt8) -> Bool)
      -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    while i < len {
      if fn(c: _bytes[i]) {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatWhile(fn: (c: UInt8) -> Bool) -> Bool {
    return matchWhile(true, fn: fn) >= 0
  }

  public mutating func matchWhile(consume: Bool = false, fn: (c: UInt8) -> Bool)
      -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      if !fn(c: _bytes[i]) {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func seekContext(fn: (c: UInt8) -> Bool) -> Bool {
    return matchContext(true, fn: fn) >= 0
  }

  public mutating func matchContext(consume: Bool = false,
      fn: (c: UInt8) -> Bool) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    while i < len {
      if fn(c: _bytes[i]) {
        if consume {
          currentIndex = i
          startIndex = i
        }
        return i
      }
      i += 1
    }
    return -1
  }

  public mutating func maybeEat(fn: (inout ctx: ByteStream) -> Bool) -> Bool {
    return maybeMatch(fn) >= 0
  }

  public mutating func maybeMatch(fn: (inout ctx: ByteStream) -> Bool) -> Int {
    let savei = currentIndex
    if fn(ctx: &self) {
      return currentIndex - savei
    } else if milestoneIndex > 0 {
      currentIndex = milestoneIndex
      milestoneIndex = 0
    } else {
      currentIndex = savei
    }
    return -1
  }

  public mutating func nestMatch(fn: (ctx: ByteStream) -> Bool) -> Int {
    var ctx = ByteStream._cloneFromPool(self)
    let savei = currentIndex
    if fn(ctx: ctx) {
      currentIndex = ctx.currentIndex
      return currentIndex - savei
    } else if ctx.milestoneIndex > 0 {
      currentIndex = ctx.milestoneIndex
      ctx.milestoneIndex = 0
    }
    ByteStream._returnToPool(ctx)
    return -1
  }

  public mutating func collectTokenString() -> String? {
    let s = currentTokenString
    startIndex = currentIndex
    return s
  }

  public mutating func collectToken() -> [UInt8] {
    let s = currentToken
    startIndex = currentIndex
    return s
  }

  static var _pool: [ByteStream] = []

  static func _returnToPool(o: ByteStream) {
    _pool.append(o)
  }

  static func _cloneFromPool(po: ByteStream) -> ByteStream {
    if _pool.count > 0 {
      var o = _pool.removeLast()
      o._bytes = po._bytes // Could clone it too.
      o.startIndex = po.startIndex
      o.lineEndIndex = po.lineEndIndex
      o.currentIndex = po.currentIndex
      return o
    } else {
      var o = ByteStream(bytes: po._bytes,
          startIndex: po.startIndex, lineEndIndex: po.lineEndIndex)
      o.currentIndex = po.currentIndex
      return o
    }
  }

  public func clone() -> ByteStream {
    var o = ByteStream(bytes: _bytes, startIndex: startIndex,
        lineEndIndex: lineEndIndex)
    o.currentIndex = currentIndex
    return o
  }

  public mutating func eatString(string: String) -> Bool {
    return matchBytes(string.bytes, consume: true) >= 0
  }

  public mutating func matchString(string: String, consume: Bool = false)
      -> Int {
    return matchBytes(string.bytes, consume: consume)
  }

  public mutating func eatBytes(bytes: [UInt8]) -> Bool {
    return matchBytes(bytes, consume: true) >= 0
  }

  public mutating func matchBytes(bytes: [UInt8], consume: Bool = false)
      -> Int {
    let i = currentIndex
    let blen = bytes.count
    if i + blen - 1 < lineEndIndex && _bytes[i] == bytes[0] {
      for bi in 1..<blen {
        if _bytes[i + bi] != bytes[bi] {
          return -1
        }
      }
      if consume {
        currentIndex += blen
      }
      return blen
    }
    return -1
  }

  public mutating func eatOnEitherString(string1: String, string2: String)
      -> Bool {
    return matchOnEitherBytes(string1.bytes, bytes2: string2.bytes,
        consume: true) >= 0
  }

  // Used for case insensitive matching.
  public mutating func matchOnEitherString(string1: String, string2: String,
      consume: Bool = false) -> Int {
    return matchOnEitherBytes(string1.bytes, bytes2: string2.bytes)
  }

  public mutating func eatOnEitherBytes(bytes1: [UInt8], bytes2: [UInt8])
      -> Bool {
    return matchOnEitherBytes(bytes1, bytes2: bytes2, consume: true) >= 0
  }

  // Used for case insensitive matching.
  public mutating func matchOnEitherBytes(bytes1: [UInt8], bytes2: [UInt8],
      consume: Bool = false) -> Int {
    let blen = bytes1.count
    let i = currentIndex
    if i + blen - 1 < lineEndIndex {
      for bi in 0..<blen {
        let c = _bytes[i + bi]
        if c != bytes1[bi] && c != bytes2[bi] {
          return -1
        }
      }
      if consume {
        currentIndex += blen
      }
      return blen
    }
    return -1
  }

  public mutating func eatUntilString(string: String) -> Bool {
    return matchUntilBytes(string.bytes, consume: true) >= 0
  }

  public mutating func matchUntilString(string: String, consume: Bool = false)
      -> Int {
    return matchUntilBytes(string.bytes, consume: consume)
  }

  public mutating func eatUntilBytes(bytes: [UInt8]) -> Bool {
    return matchUntilBytes(bytes, consume: true) >= 0
  }

  public mutating func matchUntilBytes(bytes: [UInt8], consume: Bool = false)
      -> Int {
    var i = currentIndex
    let savei = i
    let blen = bytes.count
    let len = lineEndIndex - blen + 1
    let fc = bytes[0]
    AGAIN: while i < len {
      if _bytes[i] == fc {
        for bi in 1..<blen {
          if _bytes[i + bi] != bytes[bi] {
            i += 1
            continue AGAIN
          }
        }
        if consume {
          currentIndex = i
        }
        return i - savei
      }
      i += 1
    }
    return -1
  }

  // Triple quotes sequence
  public mutating func eatUntilThree(c1: UInt8, c2: UInt8, c3: UInt8) -> Bool {
    return matchUntilThree(c1, c2: c2, c3: c3, consume: true) >= 0
  }

  public mutating func matchUntilThree(c1: UInt8, c2: UInt8, c3: UInt8,
      consume: Bool = false) -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex - 2
    while i < len {
      if _bytes[i] == c1 && _bytes[i + 1] == c2 &&
          _bytes[i + 2] == c3 {
        break
      }
      i += 1
    }
    if i >= len {
      i = lineEndIndex
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatTwo(c1: UInt8, c2: UInt8) -> Bool {
    return matchTwo(c1, c2: c2, consume: true)
  }

  public mutating func matchTwo(c1: UInt8, c2: UInt8, consume: Bool = false)
      -> Bool {
    let i = currentIndex
    if i < lineEndIndex - 1 && _bytes[i] == c1 &&
        _bytes[i + 1] == c2 {
      if consume {
        currentIndex = i + 2
      }
      return true
    }
    return false
  }

  public mutating func eatThree(c1: UInt8, c2: UInt8, c3: UInt8) -> Bool {
    return matchThree(c1, c2: c2, c3: c3, consume: true)
  }

  public mutating func matchThree(c1: UInt8, c2: UInt8, c3: UInt8,
      consume: Bool = false) -> Bool {
    let i = currentIndex
    if i < lineEndIndex - 2 && _bytes[i] == c1 &&
        _bytes[i + 1] == c2 && _bytes[i + 2] == c3 {
      if consume {
        currentIndex = i + 3
      }
      return true
    }
    return false
  }

  public mutating func eatUntilOne(c: UInt8) -> Bool {
    return matchUntilOne(c, consume: true) >= 0
  }

  public mutating func matchUntilOne(c: UInt8, consume: Bool = false) -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      if _bytes[i] == c {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatWhileNeitherTwo(c1: UInt8, c2: UInt8) -> Bool {
    return matchWhileNeitherTwo(c1, c2: c2, consume: true) >= 0
  }

  public mutating func matchWhileNeitherTwo(c1: UInt8, c2: UInt8,
      consume: Bool = false) -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _bytes[i]
      if c == c1 || c == c2 {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatWhileNeitherThree(c1: UInt8, c2: UInt8, c3: UInt8)
      -> Bool {
    return matchWhileNeitherThree(c1, c2: c2, c3: c3, consume: true) >= 0
  }

  public mutating func matchWhileNeitherThree(c1: UInt8, c2: UInt8, c3: UInt8,
      consume: Bool = false) -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _bytes[i]
      if c == c1 || c == c2 || c == c3 {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatWhileNeitherFour(c1: UInt8, c2: UInt8, c3: UInt8,
      c4: UInt8) -> Bool {
    return matchWhileNeitherFour(c1, c2: c2, c3: c3, c4: c4, consume: true) >= 0
  }

  public mutating func matchWhileNeitherFour(c1: UInt8, c2: UInt8, c3: UInt8,
      c4: UInt8, consume: Bool = false) -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _bytes[i]
      if c == c1 || c == c2 || c == c3 || c == c4 {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatWhileNeitherFive(c1: UInt8, c2: UInt8, c3: UInt8,
      c4: UInt8, c5: UInt8) -> Bool {
    return matchWhileNeitherFive(c1, c2: c2, c3: c3, c4: c4, c5: c5,
        consume: true) >= 0
  }

  public mutating func matchWhileNeitherFive(c1: UInt8, c2: UInt8, c3: UInt8,
      c4: UInt8, c5: UInt8, consume: Bool = false) -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _bytes[i]
      if c == c1 || c == c2 || c == c3 || c == c4 || c == c5 {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatWhileNeitherSix(c1: UInt8, c2: UInt8, c3: UInt8,
      c4: UInt8, c5: UInt8, c6: UInt8) -> Bool {
    return matchWhileNeitherSix(c1, c2: c2, c3: c3, c4: c4, c5: c5, c6: c6,
        consume: true) >= 0
  }

  public mutating func matchWhileNeitherSix(c1: UInt8, c2: UInt8, c3: UInt8,
      c4: UInt8, c5: UInt8, c6: UInt8, consume: Bool = false) -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _bytes[i]
      if c == c1 || c == c2 || c == c3 || c == c4 || c == c5 || c == c6 {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatWhileNeitherSeven(c1: UInt8, c2: UInt8, c3: UInt8,
      c4: UInt8, c5: UInt8, c6: UInt8, c7: UInt8) -> Bool {
    return matchWhileNeitherSeven(c1, c2: c2, c3: c3, c4: c4, c5: c5, c6: c6,
        c7: c7, consume: true) >= 0
  }

  public mutating func matchWhileNeitherSeven(c1: UInt8, c2: UInt8, c3: UInt8,
      c4: UInt8, c5: UInt8, c6: UInt8, c7: UInt8, consume: Bool = false)
      -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _bytes[i]
      if c == c1 || c == c2 || c == c3 || c == c4 || c == c5 ||
          c == c6 || c == c7 {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public var currentToken: [UInt8] {
    return [UInt8](_bytes[startIndex..<currentIndex])
  }

  public var currentTokenString: String? {
    let ei = currentIndex - 1
    return ei < startIndex ? nil :
        String.fromCharCodes(_bytes, start: startIndex, end: ei)
  }

  // More specialization

  public mutating func eatDigit() -> Bool {
    return matchDigit(true) != nil
  }

  public mutating func matchDigit(consume: Bool = false) -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i]
      if c >= 48 && c <= 57 {
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func eatWhileDigit() -> Bool {
    return matchWhileDigit(true) >= 0
  }

  public mutating func matchWhileDigit(consume: Bool = false) -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _bytes[i]
      if c < 48 || c > 57 {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatLowerCase() -> Bool {
    return matchLowerCase(true) != nil
  }

  // a-z
  public mutating func matchLowerCase(consume: Bool = false) -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i]
      if c >= 97 && c <= 122 { // a-z
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func eatWhileLowerCase() -> Bool {
    return matchWhileLowerCase(true) >= 0
  }

  public mutating func matchWhileLowerCase(consume: Bool = false) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    while i < len {
      let c = _bytes[i]
      if c < 97 || c > 122 {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatUpperCase() -> Bool {
    return matchUpperCase(true) != nil
  }

  // A-Z
  public mutating func matchUpperCase(consume: Bool = false) -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i]
      if c >= 65 && c <= 90 { // A-Z
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func eatWhileUpperCase() -> Bool {
    return matchWhileUpperCase(true) >= 0
  }

  public mutating func matchWhileUpperCase(consume: Bool = false) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    while i < len {
      let c = _bytes[i]
      if c < 65 || c > 90 {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatAlpha() -> Bool {
    return matchAlpha(true) != nil
  }

  // A-Z a-z
  public mutating func matchAlpha(consume: Bool = false) -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) { // A-Z a-z
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func eatWhileAlpha() -> Bool {
    return matchWhileAlpha(true) >= 0;
  }

  public mutating func matchWhileAlpha(consume: Bool = false) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    while i < len {
      let c = _bytes[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatAlphaUnderline() -> Bool {
    return matchAlphaUnderline(true) >= 0
  }

  // A-Z a-z _
  public mutating func matchAlphaUnderline(consume: Bool = false) -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i] // A-Z a-z _
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 {
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func eatWhileAlphaUnderline() -> Bool {
    return matchWhileAlphaUnderline(true) >= 0
  }

  public mutating func matchWhileAlphaUnderline(consume: Bool = false) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    while i < len {
      let c = _bytes[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatAlphaUnderlineDigit() -> Bool {
    return matchAlphaUnderlineDigit(true) != nil
  }

  // A-Z a-z _ 0-9
  public mutating func matchAlphaUnderlineDigit(consume: Bool = false)
      -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i] // A-Z a-z _ 0-9
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 ||
          (c >= 48 && c <= 57) {
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func eatWhileAlphaUnderlineDigit() -> Bool {
    return matchWhileAlphaUnderlineDigit(true) >= 0
  }

  public mutating func matchWhileAlphaUnderlineDigit(consume: Bool = false)
      -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    while i < len {
      let c = _bytes[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 ||
          (c >= 48 && c <= 57) {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatAlphaUnderlineDigitMinus() -> Bool {
    return matchAlphaUnderlineDigitMinus(true) != nil
  }

  // A-Z a-z _ 0-9
  public mutating func matchAlphaUnderlineDigitMinus(consume: Bool = false)
      -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i] // A-Z a-z _ 0-9 -
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 ||
          (c >= 48 && c <= 57) || c == 45 {
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func eatWhileAlphaUnderlineDigitMinus() -> Bool {
    return matchWhileAlphaUnderlineDigitMinus(true) >= 0
  }

  public mutating func matchWhileAlphaUnderlineDigitMinus(consume: Bool = false)
      -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _bytes[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 ||
          (c >= 48 && c <= 57) || c == 45 {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatAlphaDigit() -> Bool {
    return matchAlphaDigit(true) != nil
  }

  // A-Z a-z 0-9
  public mutating func matchAlphaDigit(consume: Bool = false) -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i] // A-Z a-z 0-9
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) ||
          (c >= 48 && c <= 57) {
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func eatWhileAlphaDigit() -> Bool {
    return matchWhileAlphaDigit(true) >= 0
  }

  public mutating func matchWhileAlphaDigit(consume: Bool = false) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    while i < len {
      let c = _bytes[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) ||
          (c >= 48 && c <= 57) {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatHexa() -> Bool {
    return matchHexa(true) != nil
  }

  // A-F a-f 0-9
  public mutating func matchHexa(consume: Bool = false) -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i] // A-F a-f 0-9
      if (c >= 65 && c <= 70) || (c >= 97 && c <= 102) ||
          (c >= 48 && c <= 57) {
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func eatWhileHexa() -> Bool {
    return matchWhileHexa(true) >= 0
  }

  public mutating func matchWhileHexa(consume: Bool = false) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    while i < len {
      let c = _bytes[i]
      if (c >= 65 && c <= 70) || (c >= 97 && c <= 102) ||
          (c >= 48 && c <= 57) {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  // One-off symbols

  public mutating func eatOpenParen() -> Bool {
    return matchOpenParen(true)
  }

  // (
  public mutating func matchOpenParen(consume: Bool = false) -> Bool {
    return matchOne(40, consume: consume) // (
  }

  public mutating func eatCloseParen() -> Bool {
    return matchCloseParen(true)
  }

  // )
  public mutating func matchCloseParen(consume: Bool = false) -> Bool {
    return matchOne(41, consume: consume) // )
  }

  public mutating func eatLessThan() -> Bool {
    return matchLessThan(true)
  }

  // <
  public mutating func matchLessThan(consume: Bool = false) -> Bool {
    return matchOne(60, consume: consume) // <
  }

  public mutating func eatGreaterThan() -> Bool {
    return matchGreaterThan(true)
  }

  // >
  public mutating func matchGreaterThan(consume: Bool = false) -> Bool {
    return matchOne(62, consume: consume) // >
  }

  public mutating func eatOpenBracket() -> Bool {
    return matchOpenBracket(true)
  }

  // [
  public mutating func matchOpenBracket(consume: Bool = false) -> Bool {
    return matchOne(91, consume: consume) // [
  }

  public mutating func eatCloseBracket() -> Bool {
    return matchCloseBracket(true)
  }

  // ]
  public mutating func matchCloseBracket(consume: Bool = false) -> Bool {
    return matchOne(93, consume: consume) // ]
  }

  public mutating func eatOpenBrace() -> Bool {
    return matchOpenBrace(true)
  }

  // {
  public mutating func matchOpenBrace(consume: Bool = false) -> Bool {
    return matchOne(123, consume: consume) // {
  }

  public mutating func eatCloseBrace() -> Bool {
    return matchCloseBrace(true)
  }

  // }
  public mutating func matchCloseBrace(consume: Bool = false) -> Bool {
    return matchOne(125, consume: consume) // }
  }

  public mutating func eatEqual() -> Bool {
    return matchEqual(true)
  }

  // =
  public mutating func matchEqual(consume: Bool = false) -> Bool {
    return matchOne(61, consume: consume) // =
  }

  public mutating func eatPlus() -> Bool {
    return matchPlus(true)
  }

  // +
  public mutating func matchPlus(consume: Bool = false) -> Bool {
    return matchOne(43, consume: consume) // +
  }

  public mutating func eatMinus() -> Bool {
    return matchMinus(true)
  }

  // -
  public mutating func matchMinus(consume: Bool = false) -> Bool {
    return matchOne(45, consume: consume) // -
  }

  public mutating func eatExclamation() -> Bool {
    return matchExclamation(true)
  }

  // !
  public mutating func matchExclamation(consume: Bool = false) -> Bool {
    return matchOne(33, consume: consume) // !
  }

  public mutating func eatQuestionMark() -> Bool {
    return matchQuestionMark(true)
  }

  // ?
  public mutating func matchQuestionMark(consume: Bool = false) -> Bool {
    return matchOne(63, consume: consume) // ?
  }

  public mutating func eatAmpersand() -> Bool {
    return matchAmpersand(true)
  }

  // &
  public mutating func matchAmpersand(consume: Bool = false) -> Bool {
    return matchOne(38, consume: consume) // &
  }

  public mutating func eatSemicolon() -> Bool {
    return matchSemicolon(true)
  }

  // ;
  public mutating func matchSemicolon(consume: Bool = false) -> Bool {
    return matchOne(59, consume: consume) // ;
  }

  public mutating func eatColon() -> Bool {
    return matchColon(true)
  }

  // :
  public mutating func matchColon(consume: Bool = false) -> Bool {
    return matchOne(58, consume: consume) // :
  }

  public mutating func eatPoint() -> Bool {
    return matchPoint(true)
  }

  // .
  public mutating func matchPoint(consume: Bool = false) -> Bool {
    return matchOne(46, consume: consume) // .
  }

  public mutating func eatComma() -> Bool {
    return matchComma(true)
  }

  // ,
  public mutating func matchComma(consume: Bool = false) -> Bool {
    return matchOne(44, consume: consume) // ,
  }

  public mutating func eatAsterisk() -> Bool {
    return matchAsterisk(true)
  }

  // *
  public mutating func matchAsterisk(consume: Bool = false) -> Bool {
    return matchOne(42, consume: consume) // *
  }

  public mutating func eatSlash() -> Bool {
    return matchSlash(true)
  }

  // /
  public mutating func matchSlash(consume: Bool = false) -> Bool {
    return matchOne(47, consume: consume) // /
  }

  public mutating func eatBackslash() -> Bool {
    return matchBackslash(true)
  }

  // \.
  public mutating func matchBackslash(consume: Bool = false) -> Bool {
    return matchOne(92, consume: consume) // \.
  }

  public mutating func eatAt() -> Bool {
    return matchAt(true)
  }

  // @
  public mutating func matchAt(consume: Bool = false) -> Bool {
    return matchOne(64, consume: consume) // @
  }

  public mutating func eatTilde() -> Bool {
    return matchTilde(true)
  }

  // ~
  public mutating func matchTilde(consume: Bool = false) -> Bool {
    return matchOne(126, consume: consume) // ~
  }

  public mutating func eatUnderline() -> Bool {
    return matchUnderline(true)
  }

  // _
  public mutating func matchUnderline(consume: Bool = false) -> Bool {
    return matchOne(95, consume: consume) // _
  }

  public mutating func eatPercent() -> Bool {
    return matchPercent(true)
  }

  // %
  public mutating func matchPercent(consume: Bool = false) -> Bool {
    return matchOne(37, consume: consume) // %
  }

  public mutating func eatDollar() -> Bool {
    return matchDollar(true)
  }

  // $
  public mutating func matchDollar(consume: Bool = false) -> Bool {
    return matchOne(36, consume: consume) // $
  }

  public mutating func eatSingleQuote() -> Bool {
    return matchSingleQuote(true)
  }

  // '
  public mutating func matchSingleQuote(consume: Bool = false) -> Bool {
    return matchOne(39, consume: consume) // '
  }

  public mutating func eatDoubleQuote() -> Bool {
    return matchDoubleQuote(true)
  }

  // "
  public mutating func matchDoubleQuote(consume: Bool = false) -> Bool {
    return matchOne(34, consume: consume) // "
  }

  public mutating func eatHash() -> Bool {
    return matchHash(true)
  }

  // #
  public mutating func matchHash(consume: Bool = false) -> Bool {
    return matchOne(35, consume: consume) // #
  }

  public mutating func eatPipe() -> Bool {
    return matchPipe(true)
  }

  // |
  public mutating func matchPipe(consume: Bool = false) -> Bool {
    return matchOne(124, consume: consume) // |
  }

  public mutating func eatCircumflex() -> Bool {
    return matchCircumflex(true)
  }

  // ^
  public mutating func matchCircumflex(consume: Bool = false) -> Bool {
    return matchOne(94, consume: consume) // ^
  }

  // Extended matching

  public mutating func eatInQuotes(qc: UInt8) -> Bool {
    return matchInQuotes(qc, consume: true) >= 0
  }

  public mutating func matchInQuotes(qc: UInt8, consume: Bool = false) -> Int {
    var i = currentIndex
    if qc == _bytes[i] {
      let savei = i
      let len = lineEndIndex
      i += 1
      while i < len {
        if _bytes[i] == qc {
          i += 1
          if consume {
            currentIndex = i
          }
          return i - savei
        }
        i += 1
      }
    }
    return -1
  }

  public mutating func eatInEscapedQuotes(qc: UInt8) -> Bool {
    return matchInEscapedQuotes(qc, consume: true) >= 0
  }

  public mutating func matchInEscapedQuotes(qc: UInt8, consume: Bool = false)
      -> Int {
    var i = currentIndex
    if qc == _bytes[i] {
      let savei = i
      let len = lineEndIndex
      i += 1
      while i < len {
        let c = _bytes[i]
        if c == 92 { // \.
          i += 1
        } else if c == qc {
          break
        }
        i += 1
      }
      if i < len {
        i += 1
        if consume {
          currentIndex = i
        }
        return i - savei
      }
    }
    return -1
  }

  public mutating func eatUntilEscapedString(string: String) -> Bool {
    return matchUntilEscapedString(string, consume: true) >= 0
  }

  public mutating func matchUntilEscapedString(string: String,
      consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let lei = lineEndIndex
    var sa = [UInt8](string.utf8)
    let jlen = sa.count
    let len = lei - jlen + 1
    if i < len {
      let savei = i
      var escapeCount = 0
      let fc = sa[0]
      while i < len {
        let c = _bytes[i]
        if c == 92 { // \.
          escapeCount += 1
        } else if c == fc && escapeCount % 2 == 0 {
          var j = 1
          while j < jlen {
            if _bytes[i + j] != sa[j] {
              break
            }
            j += 1
          }
          if j >= jlen {
            break
          }
        } else {
          escapeCount = 0
        }
        i += 1
      }
      if i > savei {
        r = i - savei
        if consume {
          currentIndex = i
        }
      }
    } else if (i < lei) {
      r = lei - i
      if consume {
        currentIndex = lei
      }
    }
    return r
  }

  public mutating func eatEscapingUntil(fn: (c: UInt8) -> Bool) -> Bool{
    return matchEscapingUntil(true, fn: fn) >= 0
  }

  public mutating func matchEscapingUntil(consume: Bool = false,
      fn: (c: UInt8) -> Bool) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    while i < len {
      let c = _bytes[i]
      if c == 92 { // \.
        i += 1
      } else if fn(c: c) {
        break
      }
      i += 1
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  public mutating func eatKeyword(string: String) -> Bool {
    return matchKeyword(string, consume: true) >= 0
  }

  public mutating func matchKeyword(string: String, consume: Bool = false)
      -> Int {
    var r = -1
    let sa = [UInt8](string.utf8)
    let len = sa.count
    let i = currentIndex
    if i + len <= lineEndIndex {
      currentIndex = i + len
      if matchAlphaUnderlineDigit() < 0 {
        currentIndex = i
        r = matchString(string)
        if r >= 0 && consume {
          currentIndex += len
        }
      } else {
        currentIndex = i
      }
    }
    return r
  }

  public mutating func eatKeywordFromList(firstCharTable: FirstCharTable)
      -> Bool {
    return matchKeywordFromList(firstCharTable, consume: true) >= 0
  }

  public mutating func matchKeywordFromList(firstCharTable: FirstCharTable,
      consume: Bool = false) -> Int {
    var r = -1
    let i = currentIndex
    let len = lineEndIndex
    if i < len {
      if let zz = firstCharTable[Int(_bytes[i])] {
        let jlen = zz.count
        var j = 0
        var zi = 0
        var zlen = 0
        while j < jlen {
          let z = zz[j]
          zlen = z.count
          if i + zlen <= len {
            zi = 1
            while zi < zlen {
              if _bytes[i + zi] != z[zi] {
                break
              }
              zi += 1
            }
            if zi >= zlen {
              zi = i + zlen
              if zi < len {
                let c = _bytes[zi]
                if !((c >= 65 && c <= 90) || // A-Z
                    (c >= 97 && c <= 122) || // a-z
                    (c >= 48 && c <= 57) || c == 95) { // 0-9 _
                  break
                }
              }
            }
          }
          j += 1
        }
        if j < jlen {
          r = zi
          if consume {
            currentIndex = i + zlen
          }
        }
      }
    }
    return r
  }

  // Triple quotes sequence
  public mutating func eatEscapingUntilThree(c1: UInt8, c2: UInt8, c3: UInt8)
      -> Bool {
    return matchEscapingUntilThree(c1, c2: c2, c3: c3, consume: true) >= 0
  }

  public mutating func matchEscapingUntilThree(c1: UInt8, c2: UInt8, c3: UInt8,
      consume: Bool = false) -> Int {
    var i = currentIndex
    let savei = i
    let len = lineEndIndex - 2
    var c = _bytes[i]
    var nc = _bytes[i + 1]
    while i < len {
      let nnc = _bytes[i + 2]
      if c == 92 { // \.
        i += 1
      } else if c == c1 && nc == c2 && nnc == c3 {
        break
      }
      c = nc
      nc = nnc
      i += 1
    }
    if i >= len {
      i = lineEndIndex
    }
    if i > savei {
      if consume {
        currentIndex = i
      }
      return i - savei
    }
    return -1
  }

  // String list matching

  public static func makeFirstCharTable(strings: [String]) -> FirstCharTable {
    let a: [[UInt8]] = strings.map { $0.bytes }
    return makeFirstCharTable(a)
  }

  public static func makeFirstCharTable(list: [[UInt8]]) -> FirstCharTable {
    let len = list.count
    var a = FirstCharTable(count: 256, repeatedValue: nil)
    for i in 0..<len {
      let za = list[i]
      let cint = Int(za[0])
      if a[cint] != nil {
        a[cint]!.append(za)
      } else {
        a[cint] = [za]
      }
    }
    return a
  }

  public mutating func eatBytesFromTable(firstCharTable: FirstCharTable)
      -> Bool {
    return matchBytesFromTable(firstCharTable, consume: true) >= 0
  }

  public mutating func matchBytesFromTable(firstCharTable: FirstCharTable,
      consume: Bool = false) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    if i < len {
      if let a = firstCharTable[Int(_bytes[i])] {
        if a.count == 0 {
          if consume {
            currentIndex = i + 1
          }
          return 1
        }
        BYTES: for b in a {
          let blen = b.count
          if i + blen <= len {
            for bi in 1..<blen {
              if _bytes[i + bi] != b[bi] {
                continue BYTES
              }
            }
            i += blen
            if consume {
              currentIndex = i
            }
            return i - savei
          }
        }
      }
    }
    return -1
  }

  public mutating func eatUntilIncludingBytesFromTable(
      firstCharTable: FirstCharTable) -> Bool {
    return matchUntilIncludingBytesFromTable(firstCharTable, consume: true) >= 0
  }

  public mutating func matchUntilIncludingBytesFromTable(
      firstCharTable: FirstCharTable, consume: Bool = false) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    AGAIN: while i < len {
      if let a = firstCharTable[Int(_bytes[i])] {
        if a.count == 0 {
          i += 1
          if consume {
            currentIndex = i
          }
          return i - savei
        }
        BYTES: for b in a {
          let blen = b.count
          if i + blen <= len {
            for bi in 1..<blen {
              if _bytes[i + bi] != b[bi] {
                continue BYTES
              }
            }
          } else {
            continue BYTES
          }
          i += blen
          if consume {
            currentIndex = i
          }
          return i - savei
        }
      }
      i += 1
    }
    return -1
  }

  public mutating func eatUntilIncludingString(string: String) -> Bool {
    return matchUntilIncludingBytes(string.bytes, consume: true) >= 0
  }

  public mutating func matchUntilIncludingString(string: String,
      consume: Bool = false) -> Int {
    return matchUntilIncludingBytes(string.bytes, consume: consume)
  }

  public mutating func eatUntilIncludingBytes(bytes: [UInt8]) -> Bool {
    return matchUntilIncludingBytes(bytes, consume: true) >= 0
  }

  public mutating func matchUntilIncludingBytes(bytes: [UInt8],
      consume: Bool = false) -> Int {
    var i = currentIndex
    let blen = bytes.count
    let len = lineEndIndex - blen + 1
    let fc = bytes[0]
    let savei = i
    AGAIN: while i < len {
      if _bytes[i] == fc {
        for bi in 1..<blen {
          if _bytes[i + bi] != bytes[bi] {
            i += 1
            continue AGAIN
          }
        }
        i += blen
        if consume {
          currentIndex = i
        }
        return i - savei
      }
      i += 1
    }
    return -1
  }

  public mutating func eatOneNotFromTable(firstCharTable: FirstCharTable)
      -> Bool {
    return matchOneNotFromTable(firstCharTable, consume: true) != nil
  }

  public mutating func matchOneNotFromTable(firstCharTable: FirstCharTable,
      consume: Bool = false) -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i]
      if firstCharTable[Int(c)] == nil {
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func eatOneFromTable(firstCharTable: FirstCharTable)
      -> Bool {
    return matchOneFromTable(firstCharTable, consume: true) != nil
  }

  public mutating func matchOneFromTable(firstCharTable: FirstCharTable,
      consume: Bool = false) -> UInt8? {
    let i = currentIndex
    if i < lineEndIndex {
      let c = _bytes[i]
      if firstCharTable[Int(c)] != nil {
        if consume {
          currentIndex = i + 1
        }
        return c
      }
    }
    return nil
  }

  public mutating func eatUntilBytesFromTable(firstCharTable: FirstCharTable)
      -> Bool {
    return matchUntilBytesFromTable(firstCharTable, consume: true) >= 0
  }

  public mutating func matchUntilBytesFromTable(
      firstCharTable: FirstCharTable, consume: Bool = false) -> Int {
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    OUT: while i < len {
      if let a = firstCharTable[Int(_bytes[i])] {
        if a.count == 0 {
          if consume {
            currentIndex = i
          }
          return i - savei
        }
        BYTES: for b in a {
          let blen = b.count
          if i + blen <= len {
            for bi in 1..<blen {
              if _bytes[i + bi] != b[bi] {
                continue BYTES
              }
            }
            if consume {
              currentIndex = i
            }
            break OUT
          }
        }
      }
      i += 1
    }
    if i > savei {
      return i - savei
    }
    return -1
  }

  public mutating func eatWhileBytesFromTable(firstCharTable: FirstCharTable)
      -> Bool {
    return matchWhileBytesFromTable(firstCharTable, consume: true) >= 0
  }

  // For byte lists of different sizes, the first byte list added to the table
  // that is a match will result in a short-circuit so that other matching
  // byte lists following it may not be considered until the next match loop
  // starts again. This is regardless of byte list length.
  public mutating func matchWhileBytesFromTable(firstCharTable: FirstCharTable,
      consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    AGAIN: while i < len {
      if let a = firstCharTable[Int(_bytes[i])] {
        if a.count == 0 {
          i += 1
          if consume {
            currentIndex = i
          }
          return i - savei
        }
        BYTES: for b in a {
          let blen = b.count
          if i + blen <= len {
            for bi in 1..<blen {
              if _bytes[i + bi] != b[bi] {
                continue BYTES
              }
            }
            i += blen
            if consume {
              currentIndex = i
            }
            r = i - savei
            continue AGAIN
          }
        }
      }
      break
    }
    return r
  }

  public mutating func eatStringFromListAtEnd(strings: [String]) -> Bool {
    let bytes = strings.map { $0.bytes }
    return matchBytesFromListAtEnd(bytes, consume: true) >= 0
  }

  public mutating func matchStringFromListAtEnd(strings: [String],
      consume: Bool = false) -> Int {
    let bytes = strings.map { $0.bytes }
    return matchBytesFromListAtEnd(bytes, consume: false)
  }

  public mutating func eatBytesFromListAtEnd(bytes: [[UInt8]]) -> Bool {
    return matchBytesFromListAtEnd(bytes, consume: true) >= 0
  }

  public mutating func matchBytesFromListAtEnd(bytes: [[UInt8]],
      consume: Bool = false) -> Int {
    let len = lineEndIndex
    let hostLen = len - currentIndex
    BYTES: for i in 0..<bytes.count {
      let a = bytes[i]
      let alen = a.count
      if alen <= hostLen {
        let si = len - alen
        for j in 0..<alen {
          if a[j] != _bytes[si + j] {
            continue BYTES
          }
        }
        if consume {
          currentIndex = len
        }
        return i
      }
    }
    return -1
  }

  mutating func merge(buffer: [UInt8], maxBytes: Int) {
    let len = _bytes.count
    let si = startIndex
    if si >= len {
      bytes = [UInt8](buffer[0..<maxBytes])
    } else {
      var a = [UInt8](_bytes[si..<len])
      a += buffer[0..<maxBytes]
      let offset = currentIndex - si
      bytes = a
      currentIndex = offset
    }
  }

  public static func printAscii(bytes: [UInt8]) {
    let len = bytes.count
    var a = [UInt8](count: len, repeatedValue: 0)
    for i in 0..<len {
      let c = bytes[i]
      a[i] = (c == 10 || c == 13 || (c >= 32 && c <= 126)) ? c : 46
    }
    Stdout.writeBytes(a, maxBytes: len)
    if a[len - 1] != 10 {
      print("")
    }
  }

}
