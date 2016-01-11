

public struct Header: CustomStringConvertible {

  public var method = ""
  public var uri = ""
  public var httpVersion = ""
  public var fields = [String: String]()

  public subscript(key: String) -> String? {
    get { return fields[key] ?? nil }
    set { fields[key] = newValue }
  }

  public var description: String {
    return "Header(method: \(inspect(method)), uri: \(inspect(uri)), " +
        "httpVersion: \(inspect(httpVersion)), " +
        "fields: \(inspect(fields)))"
  }

}


enum HeaderParserEntry {
  case Method
  case MethodStarted
  case Space
  case Uri
  case UriStarted
  case HttpVersion
  case HttpVersionStarted
  case LineFeed
  case CarriageReturn
  case Key
  case HeaderExit
  case KeyStarted
  case Colon
  case Value
  case ValueStarted
}


// Supports streaming.
public struct HeaderParser {

  var stream = [UInt8]()
  var entryParser: HeaderParserEntry = .Method
  public var header = Header()
  var index = 0
  var length = 0
  var linedUpParser: HeaderParserEntry = .Method
  var tokenIndex = -1
  var keyToken = ""
  var tokenBuffer = [UInt8](count: 1024, repeatedValue: 0)
  var tokenBufferEnd = 0
  var done = false
  var _bodyIndex = -1

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
      case .Method:
        try inMethod()
      case .MethodStarted:
        try inMethodStarted()
      case .Space:
        try inSpace()
      case .Uri:
        try inUri()
      case .UriStarted:
        try inUriStarted()
      case .HttpVersion:
        try inHttpVersion()
      case .HttpVersionStarted:
        try inHttpVersionStarted()
      case .LineFeed:
        try inLineFeed()
      case .CarriageReturn:
        try inCarriageReturn()
      case .Key:
        try inKey()
      case .HeaderExit:
        try inHeaderExit()
      case .KeyStarted:
        try inKeyStarted()
      case .Colon:
        try inColon()
      case .Value:
        try inValue()
      case .ValueStarted:
        try inValueStarted()
    }
  }

  mutating public func parse(bytes: [UInt8], maxBytes: Int = -1) throws {
    stream = bytes
    index = 0
    length = maxBytes < 0 ? bytes.count : maxBytes
    while index < length {
      try next()
    }
    if tokenIndex >= 0 {
      addToTokenBuffer(stream, startIndex: tokenIndex, endIndex: length)
      tokenIndex = 0 // Set it at 0 to continue supporting addToTokenBuffer.
    }
  }

  mutating func collectString(endIndex: Int) -> String? {
    var s: String?
    if tokenBufferEnd > 0 {
      addToTokenBuffer(stream, startIndex: tokenIndex, endIndex: endIndex)
      s = String.fromCharCodes(tokenBuffer, start: 0, end: tokenBufferEnd - 1)
      tokenBufferEnd = 0
    } else {
      s = String.fromCharCodes(stream, start: tokenIndex, end: endIndex - 1)
    }
    index = endIndex + 1
    tokenIndex = -1
    return s
  }

  mutating func inMethod() throws {
    let i = index
    let c = stream[i]
    if c >= 65 && c <= 90 { // A-Z
      entryParser = .MethodStarted
      tokenIndex = i
      index = i + 1
    } else {
      throw HeaderParserError.Method
    }
  }

  mutating func inMethodStarted() throws {
    var i = index
    let len = length
    repeat {
      let c = stream[i]
      if c >= 65 && c <= 90 { // A-Z
        // ignore
      } else if c == 32 {
        entryParser = .Space
        linedUpParser = .Uri
        if let m = collectString(i) {
          header.method = m
        } else {
          throw HeaderParserError.Method
        }
        break
      } else {
        throw HeaderParserError.Method
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

  mutating func inSpace() throws {
    var i = index
    var c = stream[i]
    let len = length
    while c == 32 {
      i += 1
      if i >= len {
        index = i
        return
      }
      c = stream[i]
    }
    index = i
    entryParser = linedUpParser
  }

  mutating func inUri() throws {
    let i = index
    if stream[i] > 32 {
      tokenIndex = i
      index = i + 1
      entryParser = .UriStarted
    } else {
      throw HeaderParserError.URI
    }
  }

  mutating func inUriStarted() throws {
    var i = index
    let len = length
    repeat {
      let c = stream[i]
      if c > 32 {
        // ignore
      } else if c == 32 {
        entryParser = .Space
        linedUpParser = .HttpVersion
        if let u = collectString(i) {
          header.uri = u
        } else {
          throw HeaderParserError.URI
        }
        break
      } else {
        throw HeaderParserError.URI
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

  mutating func inHttpVersion() throws {
    let i = index
    if stream[i] == 72 { // H
      tokenIndex = i
      index = i + 1
      entryParser = .HttpVersionStarted
    } else {
      throw HeaderParserError.Version
    }
  }

  mutating func inHttpVersionStarted() throws {
    var i = index
    let len = length
    func process() throws {
      if let v = collectString(i) {
        header.httpVersion = v
      } else {
        throw HeaderParserError.Version
      }
    }
    repeat {
      let c = stream[i]
      if c > 32 {
        // ignore
      } else if c == 32 {
        entryParser = .Space
        linedUpParser = .CarriageReturn
        try process()
        break
      } else if c == 13 {
        entryParser = .LineFeed
        try process()
        break
      } else if c == 10 {
        entryParser = .Key
        try process()
        break
      } else {
        throw HeaderParserError.Version
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

  mutating func inLineFeed() throws {
    if stream[index] == 10 { // \n
      index += 1
      entryParser = .Key
    } else {
      throw HeaderParserError.LineFeed
    }
  }

  mutating func inCarriageReturn() throws {
    let c = stream[index]
    if c == 13 { // \r
      index += 1
      entryParser = .LineFeed
    } else if c == 10 { // \n
      index += 1
      entryParser = .Key
    } else {
      throw HeaderParserError.CarriageReturn
    }
  }

  mutating func inKey() throws {
    let i = index
    let c = stream[i]
    if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) { // A-Z a-z
      tokenIndex = i
      index = i + 1
      entryParser = .KeyStarted
    } else if c == 10 { // \n
      done = true
      _bodyIndex = index + 1
      index = length // Header exit.
    } else if c == 13 { // \r
      index += 1
      entryParser = .HeaderExit
    } else {
      throw HeaderParserError.Key
    }
  }

  mutating func inHeaderExit() throws {
    if stream[index] == 10 { // \n
      done = true
      _bodyIndex = index + 1
      index = length
    } else {
      throw HeaderParserError.LineFeed
    }
  }

  mutating func inKeyStarted() throws {
    var i = index
    let len = length
    func process() throws {
      if let k = collectString(i) {
        keyToken = k
      } else {
        throw HeaderParserError.Key
      }
    }
    repeat {
      let c = stream[i]
      if c == 58 { // :
        entryParser = .Space
        linedUpParser = .Value
        try process()
        break
      } else if c > 32 {
        // ignore
      } else if c == 32 {
        entryParser = .Space
        linedUpParser = .Colon
        try process()
        break
      } else {
        throw HeaderParserError.Key
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

  mutating func inColon() throws {
    if stream[index] == 58 { // :
      index += 1
      entryParser = .Space
      linedUpParser = .Value
    } else {
      throw HeaderParserError.Colon
    }
  }

  mutating func inValue() throws {
    let i = index
    if stream[i] > 32 {
      tokenIndex = i
      index = i + 1
      entryParser = .ValueStarted
    } else {
      throw HeaderParserError.Value
    }
  }

  mutating func inValueStarted() throws {
    var i = index
    let len = length
    repeat {
      let c = stream[i]
      if c >= 32 {
        // ignore
      } else if c == 13 {
        entryParser = .LineFeed
        header[keyToken] = collectString(i)
        break
      } else if c == 10 {
        entryParser = .Key
        header[keyToken] = collectString(i)
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

  public var bodyIndex: Int { return _bodyIndex }

}


enum HeaderParserError: ErrorType {
  case Method
  case URI
  case Version
  case LineFeed
  case CarriageReturn
  case Key
  case Colon
  case Value
}
