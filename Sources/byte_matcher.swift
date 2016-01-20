

enum ByteMatcherEntry {
  case EatWhileLowerCase
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
}


struct ByteMatcher {


  struct EmptyParams: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
  }


  struct UInt8Param: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
    var c: UInt8
  }


  struct BytesParam: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
    var bytes: [UInt8]
  }


  struct UInt8FnParam: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
    var fn: (c: UInt8) -> Bool
  }


  struct CtxFnParam: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
    var fn: (inout ctx: ByteStream) -> Bool
  }


  struct FirstCharTableParam: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
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
      case .EatWhileLowerCase:
        return stream.eatWhileLowerCase()
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
      if !doDataMatch(data) { // No success.
        return false
      }
    }
    return true
  }

  mutating func add(entry: ByteMatcherEntry) {
    list.append(EmptyParams(entry: entry))
  }

  mutating func eatWhileLowerCase() {
    add(.EatWhileLowerCase)
  }

  mutating func eatWhileDigit() {
    add(.EatWhileDigit)
  }

  mutating func next() {
    add(.Next)
  }

  mutating func skipToEnd() {
    add(.SkipToEnd)
  }

  mutating func matchEos() {
    add(.MatchEos)
  }

  mutating func eatOne(c: UInt8) {
    list.append(UInt8Param(entry: .EatOne, c: c))
  }

  mutating func eatUntilOne(c: UInt8) {
    list.append(UInt8Param(entry: .EatUntilOne, c: c))
  }

  mutating func eatString(string: String) {
    eatBytes(string.bytes)
  }

  mutating func eatBytes(bytes: [UInt8]) {
    list.append(BytesParam(entry: .EatBytes, bytes: bytes))
  }

  mutating func eatUntilString(string: String) {
    eatUntilBytes(string.bytes)
  }

  mutating func eatUntilBytes(bytes: [UInt8]) {
    list.append(BytesParam(entry: .EatUntilBytes, bytes: bytes))
  }

  mutating func eatUntilIncludingString(string: String) {
    eatUntilIncludingBytes(string.bytes)
  }

  mutating func eatUntilIncludingBytes(bytes: [UInt8]) {
    list.append(BytesParam(entry: .EatUntilIncludingBytes, bytes: bytes))
  }

  mutating func eatUntil(fn: (c: UInt8) -> Bool) {
    list.append(UInt8FnParam(entry: .EatUntil, fn: fn))
  }

  mutating func eatOn(fn: (inout ctx: ByteStream) -> Bool) {
    list.append(CtxFnParam(entry: .EatOn, fn: fn))
  }

  mutating func eatStringFromList(list: [String]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatBytesFromTable, table: a))
  }

  mutating func eatBytesFromList(list: [[UInt8]]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatBytesFromTable, table: a))
  }

  mutating func eatOneNotFromStrings(list: [String]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatOneNotFromTable, table: a))
  }

  mutating func eatOneNotFromBytes(list: [[UInt8]]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatOneNotFromTable, table: a))
  }

  mutating func eatOneFromStrings(list: [String]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatOneFromTable, table: a))
  }

  mutating func eatOneFromBytes(list: [[UInt8]]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatOneFromTable, table: a))
  }

  mutating func eatUntilIncludingStringFromList(list: [String]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(
        entry: .EatUntilIncludingBytesFromTable, table: a))
  }

  mutating func eatUntilIncludingBytesFromList(list: [[UInt8]]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(
        entry: .EatUntilIncludingBytesFromTable, table: a))
  }

  mutating func eatWhileStringFromList(list: [String]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatWhileBytesFromTable,
        table: a))
  }

  mutating func eatWhileBytesFromList(list: [[UInt8]]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatWhileBytesFromTable,
        table: a))
  }

  mutating func eatUntilStringFromList(list: [String]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatUntilBytesFromTable,
        table: a))
  }

  mutating func eatUntilBytesFromList(list: [[UInt8]]) {
    let a = ByteStream.makeFirstCharTable(list)
    self.list.append(FirstCharTableParam(entry: .EatUntilBytesFromTable,
        table: a))
  }

}
