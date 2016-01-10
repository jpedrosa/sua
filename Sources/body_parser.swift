

public struct BodyFile {

  public var name: String?
  public var type: String?
  public var path = ""

}


public struct Body {

  public var fields = [String: String]()
  public var files = [String: BodyFile]()

  public subscript(key: String) -> String? {
    get { return fields[key] ?? nil }
    set { fields[key] = newValue }
  }

}


// DIGIT / ALPHA / "'" / "(" / ")" / "+"  / "_"
//              / "," / "-" / "." / "/" / ":" / "=" / "?"
struct BoundaryCharTable {

  let table: [Bool]

  init() {
    var t = [Bool](count: 256, repeatedValue: false)
    for i in 65..<91 { // A-Z
      t[i] = true
    }
    for i in 97..<123 { // a-z
      t[i] = true
    }
    for i in 48..<58 { // 0-9
      t[i] = true
    }
    t[39] = true // '
    t[40] = true // (
    t[41] = true // )
    t[43] = true // +
    t[44] = true // ,
    t[45] = true // -
    t[46] = true // .
    t[47] = true // /
    t[58] = true // :
    t[61] = true // =
    t[63] = true // ?
    t[95] = true // _
    table = t
  }

  subscript(key: UInt8) -> Bool { return table[Int(key)] }

  static let TABLE = BoundaryCharTable()

}


struct BodyTokenMatcher {

  let bytes: [UInt8]

  init(string: String) {
    bytes = [UInt8](string.utf8)
  }

  subscript(index: Int) -> UInt8 { return bytes[index] }

  func match(index: Int, c: UInt8) -> Bool {
    return bytes[index] == c
  }

  static let CONTENT_DISPOSITION = BodyTokenMatcher(
      string: "Content-Disposition")

  static let NAME = BodyTokenMatcher(string: "name")

  static let FILENAME = BodyTokenMatcher(string: "filename")

  static let CONTENT_TYPE = BodyTokenMatcher(string: "Content-Type")

}


enum BodyParserEntry {
  case Body
  case BodyStarted
  case Key
  case NextKey
  case KeyStarted
  case Colon
  case Value
  case ValueStarted
  case Space
  case LineFeed
  case CarriageReturn
  case Semicolon
  case Equal
  case BeginMultipart
  case BeginMultipartStarted
  case ContentDisposition
  case ContentDispositionStarted
  case ContentType
  case ContentTypeStarted
  case ContentData
  case ContentDataStarted
  case ContentFile
  case ContentFileStarted
  case EndMultipart
}


public struct BodyParser {

  var stream = [UInt8]()
  var entryParser: BodyParserEntry = .Body
  public var body = Body()
  var index = 0
  var length = 0
  var linedUpParser: BodyParserEntry = .Body
  var tokenIndex = -1
  var keyToken = ""
  var tokenBuffer = [UInt8](count: 1024, repeatedValue: 0)
  var tokenBufferEnd = 0
  var done = false
  var boundary = [UInt8]()

  public init() { }

  public var isDone: Bool { return done }

  mutating func addToTokenBuffer(a: [UInt8], startIndex: Int, endIndex: Int) {
    let tbe = tokenBufferEnd
    let blen = tokenBuffer.count
    let ne = tbe + (endIndex - startIndex)
    if ne >= blen {
      var c = [UInt8](count: ne * 2, repeatedValue: 0)
      for i in 0..<tbe {
        c[i] = tokenBuffer[i]
      }
      tokenBuffer = c
    }
    var j = tbe
    for i in startIndex..<endIndex {
      tokenBuffer[j] = a[i]
      j += 1
    }
    tokenBufferEnd = j
  }

  mutating func next() throws {
    switch entryParser {
      case .Body:
        try inBody()
      case .BodyStarted:
        try inBodyStarted()
      case .NextKey:
        try inNextKey()
      case .KeyStarted:
        try inKeyStarted()
      case .Value:
        try inValue()
      case .ValueStarted:
        try inValueStarted()
      case .BeginMultipart:
        try inBeginMultipart()
      case .BeginMultipartStarted:
        try inBeginMultipartStarted()
      // case .Space:
      //   try inSpace()
      // case .LineFeed:
      //   try inLineFeed()
      // case .CarriageReturn:
      //   try inCarriageReturn()
      // case .Key:
      //   try inKey()
      // case .Colon:
      //   try inColon()
      default: () // Ignore for now.
    }
  }

  mutating public func parse(bytes: [UInt8], index si: Int = 0,
      maxBytes: Int = -1) throws {
    stream = bytes
    index = si
    length = maxBytes < 0 ? bytes.count : maxBytes
    while index < length {
      try next()
    }
    if tokenIndex >= 0 {
      addToTokenBuffer(stream, startIndex: tokenIndex, endIndex: length)
      tokenIndex = 0 // Set it at 0 to continue supporting addToTokenBuffer.
    }
  }

  mutating func collectToken(endIndex: Int) -> [UInt8] {
    var a: [UInt8]?
    if tokenBufferEnd > 0 {
      addToTokenBuffer(stream, startIndex: tokenIndex, endIndex: endIndex)
      a = [UInt8](tokenBuffer[0..<tokenBufferEnd])
      tokenBufferEnd = 0
    } else {
      a = [UInt8](stream[tokenIndex..<endIndex])
    }
    index = endIndex + 1
    tokenIndex = -1
    return a!
  }

  mutating func collectString(endIndex: Int) -> String? {
    return String.fromCharCodes(collectToken(endIndex))
  }

  mutating func inBody() throws {
    let i = index
    let c = stream[i]
    if c == 45 { // -
      entryParser = .BeginMultipart
      tokenIndex = i
      index = i + 1
    } else if c >= 32 && c != 61 { // Some character, but not "=".
      entryParser = .KeyStarted
      tokenIndex = i
      index = i + 1
    } else {
      throw BodyParserError.Body
    }
  }

  mutating func inBodyStarted() throws {
    throw BodyParserError.Body
  }

  mutating func inBeginMultipart() throws {
    let i = index
    if stream[i] == 45 { // -
      entryParser = .BeginMultipartStarted
      tokenIndex = i
      index = i + 1
    } else {
      entryParser = .KeyStarted
    }
  }

  mutating func inBeginMultipartStarted() throws {
    var i = index
    let len = length
    repeat {
      let c = stream[i]
      if BoundaryCharTable.TABLE[c] {
        // Ignore.
      } else if c == 13 {
        entryParser = .ContentDisposition
        boundary = collectToken(i)
        if boundary.count <= 2 {
          throw BodyParserError.Key
        }
        break
      } else {
        throw BodyParserError.BeginMultipart
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

  mutating func inNextKey() throws {
    let i = index
    let c = stream[i]
    if c == 61 { // =
      throw HeaderParserError.Key
    } else if c >= 32 {
      tokenIndex = i
      index = i + 1
      entryParser = .KeyStarted
    } else {
      throw HeaderParserError.Key
    }
  }

  mutating func inKeyStarted() throws {
    var i = index
    let len = length
    func process() throws {
      if let k = collectString(i) {
        keyToken = k
      } else {
        throw BodyParserError.Key
      }
    }
    repeat {
      let c = stream[i]
      if c == 61 { // =
        entryParser = .Value
        try process()
        break
      } else if c >= 32 {
        // ignore
      } else {
        throw BodyParserError.Key
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

  mutating func inValue() throws {
    let i = index
    if stream[i] == 38 { // &
      entryParser = .NextKey
      body[keyToken] = ""
      index = i + 1
    } else if stream[i] >= 32 {
      tokenIndex = i
      index = i + 1
      entryParser = .ValueStarted
    } else if stream[i] == 13 {
      body[keyToken] = ""
      done = true
      index = length // Done. Exit.
    } else {
      throw BodyParserError.Value
    }
  }

  mutating func inValueStarted() throws {
    var i = index
    let len = length
    repeat {
      let c = stream[i]
      if c == 38 { // &
        entryParser = .NextKey
        body[keyToken] = collectString(i)
        break
      } else if c >= 32 {
        // ignore
      } else if c == 13 {
        body[keyToken] = collectString(i)
        done = true
        index = length // Done. Exit.
        break
      } else {
        throw HeaderParserError.Value
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

}


enum BodyParserError: ErrorType {
  case Body
  case Key
  case Value
  case BeginMultipart
}
