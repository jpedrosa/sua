

enum ByteMatcherEntry {
  case EatWhileDigit
  case Next
  case SkipToEnd
  case MatchEos
  case EatOne
  case EatUntilOne
  case EatBytes
  case EatUntilBytes
  case EatUntilIncludingBytes
  case EatUntil
  case EatOn
  case EatBytesFromTable
  case EatOneFromTable
  case EatOneNotFromTable
  case EatUntilIncludingBytesFromTable
  case EatWhileBytesFromTable
  case EatUntilBytesFromTable
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


  struct UInt8FnParam: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
    var optional: Bool
    var fn: (c: UInt8) -> Bool
  }


  struct CtxFnParam: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
    var optional: Bool
    var fn: (inout ctx: ByteStream) -> Bool
  }


  struct FirstCharTableParam: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
    var optional: Bool
    var table: FirstCharTable
  }


  var stream = ByteStream()
  var list = [ByteMatcherEntryData]()

  mutating func match(string: String) -> Int {
    return matchAt(string, startIndex: 0)
  }

  // Returns the length of the match, the difference between the last matched
  // index + 1 and the startIndex.
  //
  // Returns -1 in case the matching was unsuccessful.
  mutating func matchAt(string: String, startIndex: Int) -> Int {
    stream.bytes = string.bytes
    stream.startIndex = startIndex
    stream.currentIndex = startIndex
    if doMatch() {
      return stream.currentIndex - startIndex
    }
    return -1
  }

  mutating func doDataMatch(data: ByteMatcherEntryData) -> Bool {
    switch data.entry {
      case .EatWhileDigit:
        return stream.eatWhileDigit()
      case .SkipToEnd:
        return stream.skipToEnd()
      case .MatchEos:
        return stream.currentIndex >= stream.bytes.count
      case .Next:
        return stream.next() != nil
      case .EatOne:
        let c = (data as! UInt8Param).c
        return stream.eatOne(c)
      case .EatUntilOne:
        let c = (data as! UInt8Param).c
        return stream.eatUntilOne(c)
      case .EatBytes:
        let bytes = (data as! BytesParam).bytes
        return stream.eatBytes(bytes)
      case .EatUntilBytes:
        let bytes = (data as! BytesParam).bytes
        return stream.eatUntilBytes(bytes)
      case .EatUntilIncludingBytes:
        let bytes = (data as! BytesParam).bytes
        return stream.eatUntilIncludingBytes(bytes)
      case .EatUntil:
        let fn = (data as! UInt8FnParam).fn
        return stream.eatUntil(fn)
      case .EatOn:
        let fn = (data as! CtxFnParam).fn
        return stream.maybeEat(fn)
      case .EatBytesFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatBytesFromTable(table)
      case .EatOneNotFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatOneNotFromTable(table)
      case .EatOneFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatOneFromTable(table)
      case .EatUntilIncludingBytesFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatUntilIncludingBytesFromTable(table)
      case .EatWhileBytesFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatWhileBytesFromTable(table)
      case .EatUntilBytesFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatUntilBytesFromTable(table)
    }
  }

  mutating func doMatch() -> Bool {
    for data in list {
      let b = doDataMatch(data)
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

  mutating func eatUntil(optional: Bool = false, fn: (c: UInt8) -> Bool) {
    list.append(UInt8FnParam(entry: .EatUntil, optional: optional, fn: fn))
  }

  mutating func eatOn(optional: Bool = false,
      fn: (inout ctx: ByteStream) -> Bool) {
    list.append(CtxFnParam(entry: .EatOn, optional: optional, fn: fn))
  }

  mutating func eatStringFromList(list: [String], optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatBytesFromTable,
        optional: optional, table: a))
  }

  mutating func eatBytesFromList(list: [[UInt8]], optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatBytesFromTable,
        optional: optional, table: a))
  }

  mutating func eatOneNotFromStrings(list: [String], optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatOneNotFromTable,
        optional: optional, table: a))
  }

  mutating func eatOneNotFromBytes(list: [[UInt8]], optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatOneNotFromTable,
        optional: optional, table: a))
  }

  mutating func eatOneFromStrings(list: [String], optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatOneFromTable,
        optional: optional, table: a))
  }

  mutating func eatOneFromBytes(list: [[UInt8]], optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatOneFromTable,
        optional: optional, table: a))
  }

  mutating func eatUntilIncludingStringFromList(list: [String],
      optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(
        entry: .EatUntilIncludingBytesFromTable,
        optional: optional, table: a))
  }

  mutating func eatUntilIncludingBytesFromList(list: [[UInt8]],
      optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(
        entry: .EatUntilIncludingBytesFromTable,
        optional: optional, table: a))
  }

  mutating func eatWhileStringFromList(list: [String],
      optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatWhileBytesFromTable,
        optional: optional, table: a))
  }

  mutating func eatWhileBytesFromList(list: [[UInt8]],
      optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatWhileBytesFromTable,
        optional: optional, table: a))
  }

  mutating func eatUntilStringFromList(list: [String],
      optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatUntilBytesFromTable,
        optional: optional, table: a))
  }

  mutating func eatUntilBytesFromList(list: [[UInt8]],
      optional: Bool = false) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatUntilBytesFromTable,
        optional: optional, table: a))
  }

}
