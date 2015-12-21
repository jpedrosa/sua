

typealias FirstCharTable = [[[UInt8]]?]


public class CodeUnitStream: CustomStringConvertible {

  public var currentIndex = 0
  public var startIndex = 0
  public var _codeUnits: [UInt8] = []
  public var lineStartIndex = 0
  public var lineEndIndex = 0
  public var milestoneIndex = 0

  public init(codeUnits: [UInt8] = [], startIndex: Int = 0,
      lineStartIndex: Int = 0, lineEndIndex: Int = 0) {
    self.startIndex = startIndex
    self.lineStartIndex = lineStartIndex
    self.lineEndIndex = lineEndIndex
    _codeUnits = codeUnits
    currentIndex = startIndex
    if lineEndIndex == 0 {
      self.lineEndIndex = codeUnits.count
    }
  }

  public var codeUnits: [UInt8] {
    get { return _codeUnits }
    set {
      _codeUnits = newValue
      currentIndex = 0
      startIndex = 0
      lineStartIndex = 0
      lineEndIndex = newValue.count
    }
  }

  public func reset() {
    currentIndex = 0
    startIndex = 0
    lineStartIndex = 0
    lineEndIndex = _codeUnits.count
  }

  var isEol: Bool { return currentIndex >= lineEndIndex }

  var isBol: Bool { return currentIndex == lineStartIndex }

  var current: UInt8 { return _codeUnits[currentIndex] }

  func peek() -> UInt8? {
    return currentIndex < lineEndIndex ? _codeUnits[currentIndex] : nil
  }

  func next() -> UInt8? {
    var r: UInt8?
    if currentIndex < lineEndIndex {
      r = _codeUnits[currentIndex]
      currentIndex += 1
    }
    return r
  }

  func eat(fn: (c: UInt8) -> Bool) -> Bool {
    return match(true, fn: fn)
  }

  func match(consume: Bool = false, fn: (c: UInt8) -> Bool) -> Bool {
    var r = false
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i]
      if fn(c: c) {
        r = true
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func eatOne(c: UInt8) -> Bool {
    return matchOne(c, consume: true)
  }

  func matchOne(c: UInt8, consume: Bool = false) -> Bool {
    var r = false
    let i = currentIndex
    if i < lineEndIndex && c == _codeUnits[i] {
      r = true
      if consume {
        currentIndex = i + 1
      }
    }
    return r
  }

  func eatWhileOne(c: UInt8) -> Bool {
    return matchWhileOne(c, consume: true) >= 0
  }

  func matchWhileOne(c: UInt8, consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      if c != _codeUnits[i] {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatSpace() -> Bool {
    return matchSpace(true) >= 0
  }

  func eatWhileSpace() -> Bool {
    return matchWhileSpace(true) >= 0
  }

  func matchSpace(consume: Bool = false) -> UInt8? {
    var r: UInt8?
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i]
      if c == 32 || c == 160 { // space or \u00a0
        r = c
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func matchWhileSpace(consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if c != 32 && c != 160 {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatSpaceTab() -> Bool {
    return matchSpaceTab(true) != nil
  }

  func eatWhileSpaceTab() -> Bool {
    return matchWhileSpaceTab(true) >= 0
  }

  func matchSpaceTab(consume: Bool = false) -> UInt8? {
    var r: UInt8?
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i]
      if c == 32 || c == 160 || c == 9 { // space or \u00a0 or tab
        r = c
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func matchWhileSpaceTab(consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if c != 32 && c != 160 && c != 9 { // space or \u00a0 or tab
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func skipToEnd() -> Bool {
    currentIndex = lineEndIndex
    return true
  }

  func findIndexOfCodeUnit(c: UInt8, startAt: Int = 0) -> Int {
    var r = -1
    let len = _codeUnits.count
    let lim = len - 2
    var i = startAt
    while i < lim {
      if _codeUnits[i] == c || _codeUnits[i + 1] == c ||
          _codeUnits[i + 2] == c {
        break
      }
      i += 3
    }
    while i < len {
      if _codeUnits[i] == c {
        r = i
        break
      }
      i += 1
    }
    return r
  }

  func skipTo(c: UInt8) -> Int {
    let r = findIndexOfCodeUnit(c, startAt: currentIndex)
    if r >= lineStartIndex && r < lineEndIndex {
      currentIndex = r
    }
    return r
  }

  func backUp(n: Int) {
    currentIndex -= n
  }

  func keepMilestoneIfNot(fn: () -> Bool) -> Bool {
    let r = fn()
    if !r {
      milestoneIndex = currentIndex + 1
    }
    return r
  }

  func yankMilestoneIfNot(fn: () -> Bool) -> Bool {
    if !fn() {
      milestoneIndex = currentIndex + 1
    }
    return false
  }

  func eatUntil(fn: (c: UInt8) -> Bool) -> Bool {
    return matchUntil(true, fn: fn) >= 0
  }

  func matchUntil(consume: Bool = false, fn: (c: UInt8) -> Bool) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      if fn(c: _codeUnits[i]) {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatWhile(fn: (c: UInt8) -> Bool) -> Bool {
    return matchWhile(true, fn: fn) >= 0
  }

  func matchWhile(consume: Bool = false, fn: (c: UInt8) -> Bool) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      if !fn(c: _codeUnits[i]) {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func seekContext(fn: (c: UInt8) -> Bool) -> Bool {
    return matchContext(true, fn: fn) >= 0
  }

  func matchContext(consume: Bool = false, fn: (c: UInt8) -> Bool) -> Int {
    var r = -1
    var i = currentIndex
    let len = lineEndIndex
    while i < len {
      if fn(c: _codeUnits[i]) {
        r = i
        if consume {
          currentIndex = i
          startIndex = i
        }
        break
      }
      i += 1
    }
    return r
  }

  func maybeEat(fn: (ctx: CodeUnitStream) -> Bool) -> Bool {
    return maybeMatch(fn) >= 0
  }

  func maybeMatch(fn: (ctx: CodeUnitStream) -> Bool) -> Int {
    var r = -1
    let savei = currentIndex
    if fn(ctx: self) {
      r = currentIndex - savei
    } else if milestoneIndex > 0 {
      currentIndex = milestoneIndex
      milestoneIndex = 0
    } else {
      currentIndex = savei
    }
    return r
  }

  func nestMatch(fn: (ctx: CodeUnitStream) -> Bool) -> Int {
    let ctx = CodeUnitStream._cloneFromPool(self)
    var r = -1
    let savei = currentIndex
    if fn(ctx: ctx) {
      currentIndex = ctx.currentIndex
      r = currentIndex - savei
    } else if ctx.milestoneIndex > 0 {
      currentIndex = ctx.milestoneIndex
      ctx.milestoneIndex = 0
    }
    CodeUnitStream._returnToPool(ctx)
    return r
  }

  func collectTokenString() -> String? {
    let s = currentTokenString
    startIndex = currentIndex
    return s
  }

  static var _pool: [CodeUnitStream] = []

  static func _returnToPool(o: CodeUnitStream) {
    _pool.append(o)
  }

  static func _cloneFromPool(po: CodeUnitStream) -> CodeUnitStream {
    if _pool.count > 0 {
      let o = _pool.removeLast()
      o._codeUnits = po._codeUnits // Could clone it too.
      o.startIndex = po.startIndex
      o.lineStartIndex = po.lineStartIndex
      o.lineEndIndex = po.lineEndIndex
      o.currentIndex = po.currentIndex
      return o
    } else {
      let o = CodeUnitStream(codeUnits: po._codeUnits, startIndex: po.startIndex,
          lineStartIndex: po.lineStartIndex, lineEndIndex: po.lineEndIndex)
      o.currentIndex = po.currentIndex
      return o
    }
  }

  func clone() -> CodeUnitStream {
    let o = CodeUnitStream(codeUnits: _codeUnits, startIndex: startIndex,
      lineStartIndex: lineStartIndex, lineEndIndex: lineEndIndex)
    o.currentIndex = currentIndex
    return o
  }

  func eatString(string: String) -> Bool {
    return matchString(string, consume: true) >= 0
  }

  func matchString(string: String, consume: Bool = false) -> Int {
    var r = -1
    let i = currentIndex
    let savei = i
    var sa = [UInt8](string.utf8)
    let len = sa.count
    if i + len - 1 < lineEndIndex && _codeUnits[i] == sa[0] {
      var j = 1
      while j < len {
        if _codeUnits[i + j] != sa[j] {
          break
        }
        j += 1
      }
      if j >= len {
        r = savei
        if consume {
          currentIndex += len
        }
      }
    }
    return r
  }

  func eatOnEitherString(string1: String, string2: String) -> Bool {
    return matchOnEitherString(string1, string2: string2, consume: true) >= 0
  }

  // Used for case insensitive matching
  func matchOnEitherString(string1: String, string2: String,
      consume: Bool = false) -> Int {
    var r = -1
    var s1a = [UInt8](string1.utf8)
    var s2a = [UInt8](string2.utf8)
    let seqLen = s1a.count
    let i = currentIndex
    if i + seqLen - 1 < lineEndIndex {
      var j = 0
      while j < seqLen {
        let c = _codeUnits[i + j]
        if c != s1a[j] && c != s2a[j] {
          break
        }
        j += 1
      }
      if j >= seqLen {
        r = seqLen
        if consume {
          currentIndex += seqLen
        }
      }
    }
    return r
  }

  func eatUntilString(string: String) -> Bool {
    return matchUntilString(string, consume: true) >= 0
  }

  func matchUntilString(string: String, consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    var sa = [UInt8](string.utf8)
    let seqLen = sa.count
    let len = lineEndIndex - seqLen + 1
    let sfc = sa[0]
    while i < len {
      let c = _codeUnits[i]
      if c == sfc {
        var j = 1
        while j < seqLen {
          if _codeUnits[i + j] != sa[j] {
            i += j - 1
            break
          }
          j += 1
        }
        if j >= seqLen {
          break
        }
      }
      i += 1
    }
    if i >= len {
      i = lineEndIndex
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  // Triple quotes sequence
  func eatUntilThree(c1: UInt8, c2: UInt8, c3: UInt8) -> Bool {
    return matchUntilThree(c1, c2: c2, c3: c3, consume: true) >= 0
  }

  func matchUntilThree(c1: UInt8, c2: UInt8, c3: UInt8, consume: Bool = false)
      -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex - 2
    while i < len {
      if _codeUnits[i] == c1 && _codeUnits[i + 1] == c2 &&
          _codeUnits[i + 2] == c3 {
        break
      }
      i += 1
    }
    if i >= len {
      i = lineEndIndex
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatTwo(c1: UInt8, c2: UInt8) -> Bool {
    return matchTwo(c1, c2: c2, consume: true)
  }

  func matchTwo(c1: UInt8, c2: UInt8, consume: Bool = false) -> Bool {
    var r = false
    let i = currentIndex
    if i < lineEndIndex - 1 && _codeUnits[i] == c1 &&
        _codeUnits[i + 1] == c2 {
      r = true
      if consume {
        currentIndex = i + 2
      }
    }
    return r
  }

  func eatThree(c1: UInt8, c2: UInt8, c3: UInt8) -> Bool {
    return matchThree(c1, c2: c2, c3: c3, consume: true)
  }

  func matchThree(c1: UInt8, c2: UInt8, c3: UInt8, consume: Bool = false)
      -> Bool {
    var r = false
    let i = currentIndex
    if i < lineEndIndex - 2 && _codeUnits[i] == c1 &&
        _codeUnits[i + 1] == c2 && _codeUnits[i + 2] == c3 {
      r = true
      if consume {
        currentIndex = i + 3
      }
    }
    return r
  }

  func eatUntilOne(c: UInt8) -> Bool {
    return matchUntilOne(c, consume: true) >= 0
  }

  func matchUntilOne(mc: UInt8, consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      if _codeUnits[i] == mc {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatWhileNeitherTwo(c1: UInt8, c2: UInt8) -> Bool {
    return matchWhileNeitherTwo(c1, c2: c2, consume: true) >= 0
  }

  func matchWhileNeitherTwo(c1: UInt8, c2: UInt8, consume: Bool = false)
      -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if c == c1 || c == c2 {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatWhileNeitherThree(c1: UInt8, c2: UInt8, c3: UInt8) -> Bool {
    return matchWhileNeitherThree(c1, c2: c2, c3: c3, consume: true) >= 0
  }

  func matchWhileNeitherThree(c1: UInt8, c2: UInt8, c3: UInt8,
      consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if c == c1 || c == c2 || c == c3 {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatWhileNeitherFour(c1: UInt8, c2: UInt8, c3: UInt8, c4: UInt8) -> Bool {
    return matchWhileNeitherFour(c1, c2: c2, c3: c3, c4: c4, consume: true) >= 0
  }

  func matchWhileNeitherFour(c1: UInt8, c2: UInt8, c3: UInt8, c4: UInt8,
      consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if c == c1 || c == c2 || c == c3 || c == c4 {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatWhileNeitherFive(c1: UInt8, c2: UInt8, c3: UInt8, c4: UInt8,
      c5: UInt8) -> Bool {
    return matchWhileNeitherFive(c1, c2: c2, c3: c3, c4: c4, c5: c5,
        consume: true) >= 0
  }

  func matchWhileNeitherFive(c1: UInt8, c2: UInt8, c3: UInt8, c4: UInt8,
      c5: UInt8, consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if c == c1 || c == c2 || c == c3 || c == c4 || c == c5 {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatWhileNeitherSix(c1: UInt8, c2: UInt8, c3: UInt8, c4: UInt8, c5: UInt8,
      c6: UInt8) -> Bool {
    return matchWhileNeitherSix(c1, c2: c2, c3: c3, c4: c4, c5: c5, c6: c6,
        consume: true) >= 0
  }

  func matchWhileNeitherSix(c1: UInt8, c2: UInt8, c3: UInt8, c4: UInt8,
      c5: UInt8, c6: UInt8, consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if c == c1 || c == c2 || c == c3 || c == c4 || c == c5 || c == c6 {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatWhileNeitherSeven(c1: UInt8, c2: UInt8, c3: UInt8, c4: UInt8,
      c5: UInt8, c6: UInt8, c7: UInt8) -> Bool {
    return matchWhileNeitherSeven(c1, c2: c2, c3: c3, c4: c4, c5: c5, c6: c6,
        c7: c7, consume: true) >= 0
  }

  func matchWhileNeitherSeven(c1: UInt8, c2: UInt8, c3: UInt8, c4: UInt8,
      c5: UInt8, c6: UInt8, c7: UInt8, consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if c == c1 || c == c2 || c == c3 || c == c4 || c == c5 ||
          c == c6 || c == c7 {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  var currentToken: [UInt8] {
    return [UInt8](_codeUnits[startIndex..<currentIndex])
  }

  var currentTokenString: String? {
    return String.fromCharCodes(_codeUnits, start: startIndex,
        end: currentIndex - 1)
  }

  // More specialization

  func eatDigit() -> Bool {
    return matchDigit(true) != nil
  }

  func eatWhileDigit() -> Bool {
    return matchWhileDigit(true) >= 0
  }

  func matchDigit(consume: Bool = false) -> UInt8? {
    var r: UInt8?
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i]
      if c >= 48 && c <= 57 {
        r = c
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func matchWhileDigit(consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if c < 48 || c > 57 {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatLowerCase() -> Bool {
    return matchLowerCase(true) != nil
  }

  func eatLowerCases() -> Bool {
    return matchWhileLowerCase(true) >= 0
  }

  // a-z
  func matchLowerCase(consume: Bool = false) -> UInt8? {
    var r: UInt8?
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i]
      if c >= 97 && c <= 122 { // a-z
        r = c
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func matchWhileLowerCase(consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if c < 97 || c > 122 {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatUpperCase() -> Bool {
    return matchUpperCase(true) != nil
  }

  func eatWhileUpperCase() -> Bool {
    return matchWhileUpperCase(true) >= 0
  }

  // A-Z
  func matchUpperCase(consume: Bool = false) -> UInt8? {
    var r: UInt8?
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i]
      if c >= 65 && c <= 90 { // A-Z
        r = c
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func matchWhileUpperCase(consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if c < 65 || c > 90 {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatAlpha() -> Bool {
    return matchAlpha(true) != nil
  }

  func eatWhileAlpha() -> Bool {
    return matchWhileAlpha(true) >= 0;
  }

  // A-Z a-z
  func matchAlpha(consume: Bool = false) -> UInt8? {
    var r: UInt8?
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) { // A-Z a-z
        r = c
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func matchWhileAlpha(consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatAlphaUnderline() -> Bool {
    return matchAlphaUnderline(true) >= 0
  }

  func eatWhileAlphaUnderline() -> Bool {
    return matchWhileAlphaUnderline(true) >= 0
  }

  // A-Z a-z _
  func matchAlphaUnderline(consume: Bool = false) -> UInt8? {
    var r: UInt8?
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i] // A-Z a-z _
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 {
        r = c
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func matchWhileAlphaUnderline(consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatAlphaUnderlineDigit() -> Bool {
    return matchAlphaUnderlineDigit(true) != nil
  }

  func eatWhileAlphaUnderlineDigit() -> Bool {
    return matchWhileAlphaUnderlineDigit(true) >= 0
  }

  // A-Z a-z _ 0-9
  func matchAlphaUnderlineDigit(consume: Bool = false) -> UInt8? {
    var r: UInt8?
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i] // A-Z a-z _ 0-9
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 ||
          (c >= 48 && c <= 57) {
        r = c
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func matchWhileAlphaUnderlineDigit(consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 ||
          (c >= 48 && c <= 57) {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatAlphaUnderlineDigitMinus() -> Bool {
    return matchAlphaUnderlineDigitMinus(true) != nil
  }

  func eatWhileAlphaUnderlineDigitMinus() -> Bool {
    return matchWhileAlphaUnderlineDigitMinus(true) >= 0
  }

  // A-Z a-z _ 0-9
  func matchAlphaUnderlineDigitMinus(consume: Bool = false) -> UInt8? {
    var r: UInt8?
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i] // A-Z a-z _ 0-9 -
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 ||
          (c >= 48 && c <= 57) || c == 45 {
        r = c
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func matchWhileAlphaUnderlineDigitMinus(consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 ||
          (c >= 48 && c <= 57) || c == 45 {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatAlphaDigit() -> Bool {
    return matchAlphaDigit(true) != nil
  }

  func eatWhileAlphaDigit() -> Bool {
    return matchWhileAlphaDigit(true) >= 0
  }

  // A-Z a-z 0-9
  func matchAlphaDigit(consume: Bool = false) -> UInt8? {
    var r: UInt8?
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i] // A-Z a-z 0-9
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) ||
          (c >= 48 && c <= 57) {
        r = c
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func matchWhileAlphaDigit(consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) ||
          (c >= 48 && c <= 57) {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatHexa() -> Bool {
    return matchHexa(true) != nil
  }

  func eatWhileHexa() -> Bool {
    return matchWhileHexa(true) >= 0
  }

  // A-F a-f 0-9
  func matchHexa(consume: Bool = false) -> UInt8? {
    var r: UInt8?
    let i = currentIndex
    if i < lineEndIndex {
      let c = _codeUnits[i] // A-F a-f 0-9
      if (c >= 65 && c <= 70) || (c >= 97 && c <= 102) ||
          (c >= 48 && c <= 57) {
        r = c
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }

  func matchWhileHexa(consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex
    while i < len {
      let c = _codeUnits[i]
      if (c >= 65 && c <= 70) || (c >= 97 && c <= 102) ||
          (c >= 48 && c <= 57) {
        // ignore
      } else {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  // One-off symbols

  func eatOpenParen() -> Bool {
    return matchOpenParen(true)
  }

  // (
  func matchOpenParen(consume: Bool = false) -> Bool {
    return matchOne(40, consume: consume) // (
  }

  func eatCloseParen() -> Bool {
    return matchCloseParen(true)
  }

  // )
  func matchCloseParen(consume: Bool = false) -> Bool {
    return matchOne(41, consume: consume) // )
  }

  func eatLessThan() -> Bool {
    return matchLessThan(true)
  }

  // <
  func matchLessThan(consume: Bool = false) -> Bool {
    return matchOne(60, consume: consume) // <
  }

  func eatGreaterThan() -> Bool {
    return matchGreaterThan(true)
  }

  // >
  func matchGreaterThan(consume: Bool = false) -> Bool {
    return matchOne(62, consume: consume) // >
  }

  func eatOpenBracket() -> Bool {
    return matchOpenBracket(true)
  }

  // [
  func matchOpenBracket(consume: Bool = false) -> Bool {
    return matchOne(91, consume: consume) // [
  }

  func eatCloseBracket() -> Bool {
    return matchCloseBracket(true)
  }

  // ]
  func matchCloseBracket(consume: Bool = false) -> Bool {
    return matchOne(93, consume: consume) // ]
  }

  func eatOpenBrace() -> Bool {
    return matchOpenBrace(true)
  }

  // {
  func matchOpenBrace(consume: Bool = false) -> Bool {
    return matchOne(123, consume: consume) // {
  }

  func eatCloseBrace() -> Bool {
    return matchCloseBrace(true)
  }

  // }
  func matchCloseBrace(consume: Bool = false) -> Bool {
    return matchOne(125, consume: consume) // }
  }

  func eatEqual() -> Bool {
    return matchEqual(true)
  }

  // =
  func matchEqual(consume: Bool = false) -> Bool {
    return matchOne(61, consume: consume) // =
  }

  func eatPlus() -> Bool {
    return matchPlus(true)
  }

  // +
  func matchPlus(consume: Bool = false) -> Bool {
    return matchOne(43, consume: consume) // +
  }

  func eatMinus() -> Bool {
    return matchMinus(true)
  }

  // -
  func matchMinus(consume: Bool = false) -> Bool {
    return matchOne(45, consume: consume) // -
  }

  func eatExclamation() -> Bool {
    return matchExclamation(true)
  }

  // !
  func matchExclamation(consume: Bool = false) -> Bool {
    return matchOne(33, consume: consume) // !
  }

  func eatQuestionMark() -> Bool {
    return matchQuestionMark(true)
  }

  // ?
  func matchQuestionMark(consume: Bool = false) -> Bool {
    return matchOne(63, consume: consume) // ?
  }

  func eatAmpersand() -> Bool {
    return matchAmpersand(true)
  }

  // &
  func matchAmpersand(consume: Bool = false) -> Bool {
    return matchOne(38, consume: consume) // &
  }

  func eatSemicolon() -> Bool {
    return matchSemicolon(true)
  }

  // ;
  func matchSemicolon(consume: Bool = false) -> Bool {
    return matchOne(59, consume: consume) // ;
  }

  func eatColon() -> Bool {
    return matchColon(true)
  }

  // :
  func matchColon(consume: Bool = false) -> Bool {
    return matchOne(58, consume: consume) // :
  }

  func eatPoint() -> Bool {
    return matchPoint(true)
  }

  // .
  func matchPoint(consume: Bool = false) -> Bool {
    return matchOne(46, consume: consume) // .
  }

  func eatComma() -> Bool {
    return matchComma(true)
  }

  // ,
  func matchComma(consume: Bool = false) -> Bool {
    return matchOne(44, consume: consume) // ,
  }

  func eatAsterisk() -> Bool {
    return matchAsterisk(true)
  }

  // *
  func matchAsterisk(consume: Bool = false) -> Bool {
    return matchOne(42, consume: consume) // *
  }

  func eatSlash() -> Bool {
    return matchSlash(true)
  }

  // /
  func matchSlash(consume: Bool = false) -> Bool {
    return matchOne(47, consume: consume) // /
  }

  func eatBackslash() -> Bool {
    return matchBackslash(true)
  }

  // \.
  func matchBackslash(consume: Bool = false) -> Bool {
    return matchOne(92, consume: consume) // \.
  }

  func eatAt() -> Bool {
    return matchAt(true)
  }

  // @
  func matchAt(consume: Bool = false) -> Bool {
    return matchOne(64, consume: consume) // @
  }

  func eatTilde() -> Bool {
    return matchTilde(true)
  }

  // ~
  func matchTilde(consume: Bool = false) -> Bool {
    return matchOne(126, consume: consume) // ~
  }

  func eatUnderline() -> Bool {
    return matchUnderline(true)
  }

  // _
  func matchUnderline(consume: Bool = false) -> Bool {
    return matchOne(95, consume: consume) // _
  }

  func eatPercent() -> Bool {
    return matchPercent(true)
  }

  // %
  func matchPercent(consume: Bool = false) -> Bool {
    return matchOne(37, consume: consume) // %
  }

  func eatDollar() -> Bool {
    return matchDollar(true)
  }

  // $
  func matchDollar(consume: Bool = false) -> Bool {
    return matchOne(36, consume: consume) // $
  }

  func eatSingleQuote() -> Bool {
    return matchSingleQuote(true)
  }

  // '
  func matchSingleQuote(consume: Bool = false) -> Bool {
    return matchOne(39, consume: consume) // '
  }

  func eatDoubleQuote() -> Bool {
    return matchDoubleQuote(true)
  }

  // "
  func matchDoubleQuote(consume: Bool = false) -> Bool {
    return matchOne(34, consume: consume) // "
  }

  func eatHash() -> Bool {
    return matchHash(true)
  }

  // #
  func matchHash(consume: Bool = false) -> Bool {
    return matchOne(35, consume: consume) // #
  }

  func eatPipe() -> Bool {
    return matchPipe(true)
  }

  // |
  func matchPipe(consume: Bool = false) -> Bool {
    return matchOne(124, consume: consume) // |
  }

  func eatCircumflex() -> Bool {
    return matchCircumflex(true)
  }

  // ^
  func matchCircumflex(consume: Bool = false) -> Bool {
    return matchOne(94, consume: consume) // ^
  }

  // Extended matching

  func eatInQuotes(qc: UInt8) -> Bool {
    return matchInQuotes(qc, consume: true) >= 0
  }

  func matchInQuotes(qc: UInt8, consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    if qc == _codeUnits[i] {
      let savei = i
      let len = lineEndIndex
      i += 1
      while i < len {
        if _codeUnits[i] == qc {
          i += 1
          r = i - savei
          if consume {
            currentIndex = i
          }
          break
        }
        i += 1
      }
    }
    return r
  }

  func eatInEscapedQuotes(qc: UInt8) -> Bool {
    return matchInEscapedQuotes(qc, consume: true) >= 0
  }

  func matchInEscapedQuotes(qc: UInt8, consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    if qc == _codeUnits[i] {
      let savei = i
      let len = lineEndIndex
      i += 1
      while i < len {
        let c = _codeUnits[i]
        if c == 92 { // \.
          i += 1
        } else if c == qc {
          break
        }
        i += 1
      }
      if i < len {
        i += 1
        r = i - savei
        if consume {
          currentIndex = i
        }
      }
    }
    return r
  }

  func eatUntilEscapedString(string: String) -> Bool {
    return matchUntilEscapedString(string, consume: true) >= 0
  }

  func matchUntilEscapedString(string: String, consume: Bool = false) -> Int {
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
        let c = _codeUnits[i]
        if c == 92 { // \.
          escapeCount += 1
        } else if c == fc && escapeCount % 2 == 0 {
          var j = 1
          while j < jlen {
            if _codeUnits[i + j] != sa[j] {
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

  func eatEscapingUntil(fn: (c: UInt8) -> Bool) -> Bool{
    return matchEscapingUntil(true, fn: fn) >= 0
  }

  func matchEscapingUntil(consume: Bool = false, fn: (c: UInt8) -> Bool)
      -> Int {
    var r = -1
    var i = currentIndex
    let len = lineEndIndex
    let savei = i
    while i < len {
      let c = _codeUnits[i]
      if c == 92 { // \.
        i += 1
      } else if fn(c: c) {
        break
      }
      i += 1
    }
    if i > savei {
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  func eatKeyword(string: String) -> Bool {
    return matchKeyword(string, consume: true) >= 0
  }

  func matchKeyword(string: String, consume: Bool = false) -> Int {
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

  func eatKeywordFromList(firstCharTable: FirstCharTable) -> Bool {
    return matchKeywordFromList(firstCharTable, consume: true) >= 0
  }

  func matchKeywordFromList(firstCharTable: FirstCharTable,
      consume: Bool = false) -> Int {
    var r = -1
    let i = currentIndex
    let len = lineEndIndex
    if i < len {
      if let zz = firstCharTable[Int(_codeUnits[i])] {
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
              if _codeUnits[i + zi] != z[zi] {
                break
              }
              zi += 1
            }
            if zi >= zlen {
              zi = i + zlen
              if zi < len {
                let c = _codeUnits[zi]
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
  func eatEscapingUntilThree(c1: UInt8, c2: UInt8, c3: UInt8) -> Bool {
    return matchEscapingUntilThree(c1, c2: c2, c3: c3, consume: true) >= 0
  }

  func matchEscapingUntilThree(c1: UInt8, c2: UInt8, c3: UInt8,
      consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let savei = i
    let len = lineEndIndex - 2
    var c = _codeUnits[i]
    var nc = _codeUnits[i + 1]
    while i < len {
      let nnc = _codeUnits[i + 2]
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
      r = i - savei
      if consume {
        currentIndex = i
      }
    }
    return r
  }

  // String list matching

  func makeFirstCharTable(strings: [String]) -> FirstCharTable {
    let len = strings.count
    var a = FirstCharTable(count: 256, repeatedValue: nil)
    for i in 0..<len {
      let za = [UInt8](strings[i].utf8)
      let c = za[0]
      let cint = Int(c)
      var zz = a[cint]
      if zz != nil {
        zz!.append(za)
      } else {
        a[cint] = [za]
      }
    }
    return a
  }

  func eatStringFromList(firstCharTable: FirstCharTable) -> Bool {
    return matchStringFromList(firstCharTable, consume: true) >= 0
  }

  func matchStringFromList(firstCharTable: FirstCharTable,
      consume: Bool = false) -> Int {
    var r = -1
    let i = currentIndex
    let len = lineEndIndex
    if i < len {
      if let zz = firstCharTable[Int(_codeUnits[i])] {
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
              if _codeUnits[i + zi] != z[zi] {
                break
              }
              zi += 1
            }
            if zi >= zlen {
              break
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

  func eatUntilIncludingStringFromList(firstCharTable: FirstCharTable) -> Bool {
    return matchUntilIncludingStringFromList(firstCharTable, consume: true) >= 0
  }

  func matchUntilIncludingStringFromList(firstCharTable: FirstCharTable,
      consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let len = lineEndIndex
    if i < len {
      var zi = -1
      while i < len {
        let c = _codeUnits[i]
        if let zz = firstCharTable[Int(c)] {
          let jlen = zz.count
          var j = 0
          var zlen = 0
          while j < jlen {
            let z = zz[j]
            zlen = z.count
            if i + zlen <= len {
              zi = 1
              while zi < zlen {
                if _codeUnits[i + zi] != z[zi] {
                  break
                }
                zi += 1
              }
              if zi >= zlen {
                break
              }
            }
            j += 1
          }
          if j < jlen {
            r = zi
            if consume {
              currentIndex = i + zlen
            }
            break
          }
        }
        i += 1
      }
    }
    return r
  }

  func eatUntilIncludingString(string: String) -> Bool {
    return matchUntilIncludingString(string, consume: true) >= 0
  }

  func matchUntilIncludingString(string: String, consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    var sa = [UInt8](string.utf8)
    let zlen = sa.count
    let len = lineEndIndex - zlen + 1
    if i < len {
      let sfc = sa[0]
      while i < len {
        if _codeUnits[i] == sfc {
          var zi = 1
          while zi < zlen {
            if _codeUnits[i + zi] != sa[zi] {
              break
            }
            zi += 1
          }
          if zi >= zlen {
            r = i + zlen
            if consume {
              currentIndex = r
            }
            break
          }
        }
        i += 1
      }
    }
    return r
  }

  /*func eatIfNotStringFromList(strings: [String]) -> Bool {
    return matchIfNotStringFromList(strings, consume: true) >= 0
  }

  func matchIfNotStringFromList(strings: [String], consume: Bool = false)
      -> Int {
    var r = -1
    let i = currentIndex
    if i < lineEndIndex {
      if matchStringFromList(strings) < 0 {
        r = 1
        if consume {
          currentIndex = i + 1
        }
      }
    }
    return r
  }*/

  func eatWhileNotStringFromList(firstCharTable: FirstCharTable) -> Bool {
    return matchWhileNotStringFromList(firstCharTable, consume: true) >= 0
  }

  func matchWhileNotStringFromList(firstCharTable: FirstCharTable,
      consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let len = lineEndIndex
    if i < len {
      let savei = i
      while i < len {
        let c = _codeUnits[i]
        if let zz = firstCharTable[Int(c)] {
          let jlen = zz.count
          var j = 0
          while j < jlen {
            let z = zz[j]
            let zlen = z.count
            if i + zlen <= len {
              var zi = 1
              while zi < zlen {
                if _codeUnits[i + zi] != z[zi] {
                  break
                }
                zi += 1
              }
              if zi >= zlen {
                break
              }
            }
            j += 1
          }
          if j < jlen {
            break
          }
        }
        i += 1
      }
      if i > savei {
        r = i - savei
        if consume {
          currentIndex = i
        }
      }
    }
    return r
  }

  func eatWhileStringFromList(firstCharTable: FirstCharTable) -> Bool {
    return matchWhileStringFromList(firstCharTable, consume: true) >= 0
  }

  func matchWhileStringFromList(firstCharTable: FirstCharTable,
      consume: Bool = false) -> Int {
    var r = -1
    var i = currentIndex
    let len = lineEndIndex
    if i < len {
      let savei = i
      while i < len {
        let c = _codeUnits[i]
        if let zz = firstCharTable[Int(c)] {
          let jlen = zz.count
          var j = 0
          while j < jlen {
            let z = zz[j]
            let zlen = z.count
            if i + zlen <= len {
              var zi = 1
              while zi < zlen {
                if _codeUnits[i + zi] != z[zi] {
                  break
                }
                zi += 1
              }
              if zi >= zlen {
                break
              }
            }
            j += 1
          }
          if j >= jlen {
            break
          }
        } else {
          break
        }
        i += 1
      }
      if i > savei {
        r = i - savei
        if consume {
          currentIndex = i
        }
      }
    }
    return r
  }

  public var description: String {
    return "CodeUnitStream(currentIndex: \(currentIndex), " +
      "startIndex: \(startIndex), codeUnits: \(inspect(_codeUnits)), " +
      "lineStartIndex: \(lineStartIndex), lineEndIndex: \(lineEndIndex))"
  }

}
