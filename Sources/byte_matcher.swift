

public enum ByteMatcherEntry {
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
  case EatBytesFromListAtEnd
}


public protocol ByteMatcherEntryData {
  var entry: ByteMatcherEntry { get }
}


public struct ByteMatcher {


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


  struct ListParam: ByteMatcherEntryData {
    var entry: ByteMatcherEntry
    var list: [[UInt8]]
  }


  var stream = ByteStream()
  var list = [ByteMatcherEntryData]()

  public mutating func match(string: String) -> Int {
    return matchAt(string: string, startIndex: 0)
  }

  // Returns the length of the match, the difference between the last matched
  // index + 1 and the startIndex.
  //
  // Returns -1 in case the matching was unsuccessful.
  public mutating func matchAt(string: String, startIndex: Int) -> Int {
    stream.bytes = string.bytes
    stream.startIndex = startIndex
    stream.currentIndex = startIndex
    if doMatch() {
      return stream.currentIndex - startIndex
    }
    return -1
  }

  public mutating func doDataMatch(data: ByteMatcherEntryData) -> Bool {
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
        return stream.eatOne(c: c)
      case .EatUntilOne:
        let c = (data as! UInt8Param).c
        return stream.eatUntilOne(c: c)
      case .EatBytes:
        let bytes = (data as! BytesParam).bytes
        return stream.eatBytes(bytes: bytes)
      case .EatUntilBytes:
        let bytes = (data as! BytesParam).bytes
        return stream.eatUntilBytes(bytes: bytes)
      case .EatUntilIncludingBytes:
        let bytes = (data as! BytesParam).bytes
        return stream.eatUntilIncludingBytes(bytes: bytes)
      case .EatUntil:
        let fn = (data as! UInt8FnParam).fn
        return stream.eatUntil(fn: fn)
      case .EatOn:
        let fn = (data as! CtxFnParam).fn
        return stream.maybeEat(fn: fn)
      case .EatBytesFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatBytesFromTable(firstCharTable: table)
      case .EatOneNotFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatOneNotFromTable(firstCharTable: table)
      case .EatOneFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatOneFromTable(firstCharTable: table)
      case .EatUntilIncludingBytesFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatUntilIncludingBytesFromTable(firstCharTable: table)
      case .EatWhileBytesFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatWhileBytesFromTable(firstCharTable: table)
      case .EatUntilBytesFromTable:
        let table = (data as! FirstCharTableParam).table
        return stream.eatUntilBytesFromTable(firstCharTable: table)
      case .EatBytesFromListAtEnd:
        let list = (data as! ListParam).list
        return stream.eatBytesFromListAtEnd(bytes: list)
    }
  }

  public mutating func doMatch() -> Bool {
    for data in list {
      if !doDataMatch(data: data) { // No success.
        return false
      }
    }
    return true
  }

  public mutating func add(entry: ByteMatcherEntry) {
    list.append(EmptyParams(entry: entry))
  }

  public mutating func eatWhileDigit() {
    add(entry: .EatWhileDigit)
  }

  public mutating func next() {
    add(entry: .Next)
  }

  public mutating func skipToEnd() {
    add(entry: .SkipToEnd)
  }

  public mutating func matchEos() {
    add(entry: .MatchEos)
  }

  public mutating func eatOne(c: UInt8) {
    list.append(UInt8Param(entry: .EatOne, c: c))
  }

  public mutating func eatUntilOne(c: UInt8) {
    list.append(UInt8Param(entry: .EatUntilOne, c: c))
  }

  public mutating func eatString(string: String) {
    eatBytes(bytes: string.bytes)
  }

  public mutating func eatBytes(bytes: [UInt8]) {
    list.append(BytesParam(entry: .EatBytes, bytes: bytes))
  }

  public mutating func eatUntilString(string: String) {
    eatUntilBytes(bytes: string.bytes)
  }

  public mutating func eatUntilBytes(bytes: [UInt8]) {
    list.append(BytesParam(entry: .EatUntilBytes, bytes: bytes))
  }

  public mutating func eatUntilIncludingString(string: String) {
    eatUntilIncludingBytes(bytes: string.bytes)
  }

  public mutating func eatUntilIncludingBytes(bytes: [UInt8]) {
    list.append(BytesParam(entry: .EatUntilIncludingBytes, bytes: bytes))
  }

  public mutating func eatUntil(fn: (c: UInt8) -> Bool) {
    list.append(UInt8FnParam(entry: .EatUntil, fn: fn))
  }

  public mutating func eatOn(fn: (inout ctx: ByteStream) -> Bool) {
    list.append(CtxFnParam(entry: .EatOn, fn: fn))
  }

  public mutating func eatStringFromList(list: [String]) {
    eatBytesFromTable(table: ByteStream.makeFirstCharTable(strings: list))
  }

  public mutating func eatBytesFromList(list: [[UInt8]]) {
    eatBytesFromTable(table: ByteStream.makeFirstCharTable(list: list))
  }

  public mutating func eatBytesFromTable(table: FirstCharTable) {
    list.append(FirstCharTableParam(entry: .EatBytesFromTable, table: table))
  }

  public mutating func eatOneNotFromStrings(list: [String]) {
    eatOneNotFromTable(table: ByteStream.makeFirstCharTable(strings: list))
  }

  public mutating func eatOneNotFromBytes(list: [[UInt8]]) {
    eatOneNotFromTable(table: ByteStream.makeFirstCharTable(list: list))
  }

  public mutating func eatOneNotFromTable(table: FirstCharTable) {
    list.append(FirstCharTableParam(entry: .EatOneNotFromTable, table: table))
  }

  public mutating func eatOneFromStrings(list: [String]) {
    eatOneFromTable(table: ByteStream.makeFirstCharTable(strings: list))
  }

  public mutating func eatOneFromBytes(list: [[UInt8]]) {
    eatOneFromTable(table: ByteStream.makeFirstCharTable(list: list))
  }

  public mutating func eatOneFromTable(table: FirstCharTable) {
    list.append(FirstCharTableParam(entry: .EatOneFromTable, table: table))
  }

  public mutating func eatUntilIncludingStringFromList(list: [String]) {
    eatUntilIncludingBytesFromTable(table:
        ByteStream.makeFirstCharTable(strings: list))
  }

  public mutating func eatUntilIncludingBytesFromList(list: [[UInt8]]) {
    eatUntilIncludingBytesFromTable(table:
        ByteStream.makeFirstCharTable(list: list))
  }

  public mutating func eatUntilIncludingBytesFromTable(table: FirstCharTable) {
    list.append(FirstCharTableParam(
        entry: .EatUntilIncludingBytesFromTable, table: table))
  }

  public mutating func eatWhileStringFromList(list: [String]) {
    eatWhileBytesFromTable(table: ByteStream.makeFirstCharTable(strings: list))
  }

  public mutating func eatWhileBytesFromList(list: [[UInt8]]) {
    eatWhileBytesFromTable(table: ByteStream.makeFirstCharTable(list: list))
  }

  public mutating func eatWhileBytesFromTable(table: FirstCharTable) {
    list.append(FirstCharTableParam(entry: .EatWhileBytesFromTable,
        table: table))
  }

  public mutating func eatUntilStringFromList(list: [String]) {
    eatUntilBytesFromTable(table: ByteStream.makeFirstCharTable(strings: list))
  }

  public mutating func eatUntilBytesFromList(list: [[UInt8]]) {
    eatUntilBytesFromTable(table: ByteStream.makeFirstCharTable(list: list))
  }

  public mutating func eatUntilBytesFromTable(table: FirstCharTable) {
    list.append(FirstCharTableParam(entry: .EatUntilBytesFromTable,
        table: table))
  }

  public mutating func eatStringFromListAtEnd(list: [String]) {
    eatBytesFromListAtEnd(list: list.map { $0.bytes })
  }

  public mutating func eatBytesFromListAtEnd(list: [[UInt8]]) {
    self.list.append(ListParam(entry: .EatBytesFromListAtEnd, list: list))
  }

}
