

public struct BodyFile {

  public var name = ""
  public var contentType = ""
  public var file: File

  // Handy method that can both rename and move the file to a new directory.
  public func rename(path: String) throws {
    try File.rename(file.path, newPath: path)
  }

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

  init(bytes: [UInt8]) {
    self.bytes = bytes
  }

  subscript(index: Int) -> UInt8 { return bytes[index] }

  func match(index: Int, c: UInt8) -> Bool {
    return bytes[index] == c
  }

  var count: Int { return bytes.count }

  static let CONTENT_DISPOSITION = BodyTokenMatcher(
      string: "Content-Disposition")

  static let NAME = BodyTokenMatcher(string: "name")

  static let FILENAME = BodyTokenMatcher(string: "filename")

  static let CONTENT_TYPE = BodyTokenMatcher(string: "Content-Type")

  static let FORM_DATA = BodyTokenMatcher(string: "form-data")

  static let _EMPTY = BodyTokenMatcher(string: "")

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
  case BeginMultipart
  case BeginMultipartStarted
  case MatchToken
  case ContentDisposition
  case ContentDispositionEnd
  case FormData
  case FormDataEnd
  case Name
  case NameEnd
  case NameValue
  case NameValueStarted
  case NameValueEnd
  case FileName
  case FileNameEnd
  case FileNameValue
  case FileNameValueStarted
  case FileNameValueEnd
  case ContentType
  case ContentTypeEnd
  case ContentTypeValue
  case ContentTypeValueStarted
  case ContentValue
  case ContentBody
  case ContentBodyStarted
  case ContentData
  case ContentDataStarted
  case ContentFile
  case ContentFileStarted
}


// Supports streaming.
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
  var boundary = BodyTokenMatcher._EMPTY
  var shadowMatch = BodyTokenMatcher._EMPTY
  var nameValue = ""
  var fileNameValue = ""
  var contentTypeValue = ""
  var boundaryMatch = [Int]()
  var boundTest1 = false // Match for the boundary token without line ending.
  var boundTest2 = false // Match for the boundary token plus first - suffix.
  var boundTest3 = false // Match for the boundary token plus -- suffix.
  var tempFile: TempFile?

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
      case .ContentDisposition:
        try inContentDisposition()
      case .ContentDispositionEnd:
        try inContentDispositionEnd()
      case .LineFeed:
        try inLineFeed()
      case .MatchToken:
        try inMatchToken()
      case .Space:
        try inSpace()
      case .FormData:
        try inFormData()
      case .FormDataEnd:
        try inFormDataEnd()
      case .Name:
        try inName()
      case .NameEnd:
        try inNameEnd()
      case .NameValue:
        try inNameValue()
      case .NameValueStarted:
        try inNameValueStarted()
      case .NameValueEnd:
        try inNameValueEnd()
      case .FileName:
        try inFileName()
      case .FileNameEnd:
        try inFileNameEnd()
      case .FileNameValue:
        try inFileNameValue()
      case .FileNameValueStarted:
        try inFileNameValueStarted()
      case .FileNameValueEnd:
        try inFileNameValueEnd()
      case .ContentType:
        try inContentType()
      case .ContentTypeEnd:
        try inContentTypeEnd()
      case .ContentTypeValue:
        try inContentTypeValue()
      case .ContentTypeValueStarted:
        try inContentTypeValueStarted()
      case .ContentBody:
        try inContentBody()
      case .ContentBodyStarted:
        try inContentBodyStarted()
      case .ContentData:
        try inContentData()
      case .ContentDataStarted:
        try inContentDataStarted()
      default: throw BodyParserError.ContentBody
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
      if let tf = tempFile {
        if tokenBufferEnd >= 4096 {
          let len = tokenBufferEnd - 80
          tf.writeBytes(tokenBuffer, maxBytes: len)
          for i in 0..<80 {
            tokenBuffer[i] = tokenBuffer[len + i]
          }
          tokenBufferEnd = 80
        }
      }
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

  mutating func collectFormUrlDecodedString(endIndex: Int) -> String? {
    let a = collectToken(endIndex)
    if let b = HexaUtils.formUrlDecode(a, maxBytes: a.count) {
      return String.fromCharCodes(b)
    }
    return nil
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
        boundary = BodyTokenMatcher(bytes: collectToken(i))
        if boundary.count <= 2 {
          throw BodyParserError.Key
        }
        entryParser = .LineFeed
        linedUpParser = .ContentDisposition
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
      if let k = collectFormUrlDecodedString(i) {
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
    } else if stream[i] == 0 {
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
        body[keyToken] = collectFormUrlDecodedString(i)
        break
      } else if c >= 32 {
        // ignore
      } else if c == 0 {
        body[keyToken] = collectFormUrlDecodedString(i)
        done = true
        index = length // Done. Exit.
        break
      } else {
        throw BodyParserError.Value
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
      entryParser = linedUpParser
    } else {
      throw BodyParserError.LineFeed
    }
  }

  mutating func inContentDisposition() throws {
    shadowMatch = BodyTokenMatcher.CONTENT_DISPOSITION
    entryParser = .MatchToken
    linedUpParser = .ContentDispositionEnd
    tokenIndex = index
  }

  mutating func inContentDispositionEnd() throws {
    if stream[index] == 58 { // :
      index += 1
      entryParser = .Space
      linedUpParser = .FormData
    } else {
      throw BodyParserError.ContentDisposition
    }
  }

  mutating func inFormData() throws {
    shadowMatch = BodyTokenMatcher.FORM_DATA
    entryParser = .MatchToken
    linedUpParser = .FormDataEnd
    tokenIndex = index
    try inMatchToken()
  }

  mutating func inFormDataEnd() throws {
    if stream[index] == 59 { // ;
      index += 1
      entryParser = .Space
      linedUpParser = .Name
    } else {
      throw BodyParserError.FormData
    }
  }

  mutating func inName() throws {
    shadowMatch = BodyTokenMatcher.NAME
    entryParser = .MatchToken
    linedUpParser = .NameEnd
    tokenIndex = index
    try inMatchToken()
  }

  mutating func inNameEnd() throws {
    if stream[index] == 61 { // =
      index += 1
      entryParser = .NameValue
    } else {
      throw BodyParserError.Name
    }
  }

  mutating func inNameValue() throws {
    if stream[index] == 34 { // "
      index += 1
      nameValue = ""
      entryParser = .NameValueStarted
      tokenIndex = index
    } else {
      throw BodyParserError.NameValue
    }
  }

  mutating func inNameValueStarted() throws {
    var i = index
    let len = length
    repeat {
      let c = stream[i]
      if c == 34 { // "
        if let s = collectString(i) {
          nameValue = s
        } else {
          throw BodyParserError.NameValue
        }
        entryParser = .NameValueEnd
        index = i + 1
        break
      } else if c >= 32 { // Space.
        // ignore
      } else {
        throw BodyParserError.NameValue
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

  mutating func inNameValueEnd() throws {
    if stream[index] == 59 { // ;
      index += 1
      entryParser = .Space
      linedUpParser = .FileName
    } else if stream[index] == 13 { // Carriage return.
      entryParser = .ContentBody
      index += 1
    } else {
      throw BodyParserError.NameValue
    }
  }

  mutating func inFileName() throws {
    shadowMatch = BodyTokenMatcher.FILENAME
    entryParser = .MatchToken
    linedUpParser = .FileNameEnd
    tokenIndex = index
    try inMatchToken()
  }

  mutating func inFileNameEnd() throws {
    if stream[index] == 61 { // =
      index += 1
      entryParser = .FileNameValue
    } else {
      throw BodyParserError.FileName
    }
  }

  mutating func inFileNameValue() throws {
    if stream[index] == 34 { // "
      index += 1
      tokenIndex = index
      fileNameValue = ""
      entryParser = .FileNameValueStarted
    } else {
      throw BodyParserError.FileNameValue
    }
  }

  mutating func inFileNameValueStarted() throws {
    var i = index
    let len = length
    repeat {
      let c = stream[i]
      if c == 34 { // "
        if let s = collectString(i) {
          fileNameValue = s
        } else {
          throw BodyParserError.FileNameValue
        }
        entryParser = .FileNameValueEnd
        index = i + 1
        break
      } else if c >= 32 { // Space.
        // ignore
      } else {
        throw BodyParserError.FileNameValue
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

  mutating func inFileNameValueEnd() throws {
    if stream[index] == 13 { // Carriage return.
      entryParser = .LineFeed
      linedUpParser = .ContentType
      index += 1
    } else {
      throw BodyParserError.FileNameValue
    }
  }

  mutating func inContentType() throws {
    shadowMatch = BodyTokenMatcher.CONTENT_TYPE
    entryParser = .MatchToken
    linedUpParser = .ContentTypeEnd
    tokenIndex = index
    try inMatchToken()
  }

  mutating func inContentTypeEnd() throws {
    if stream[index] == 58 { // :
      index += 1
      entryParser = .Space
      linedUpParser = .ContentTypeValue
    } else {
      throw BodyParserError.ContentDisposition
    }
  }

  mutating func inContentTypeValue() throws {
    if stream[index] > 32 {
      tokenIndex = index
      contentTypeValue = ""
      index += 1
      entryParser = .ContentTypeValueStarted
    } else {
      throw BodyParserError.ContentTypeValue
    }
  }

  mutating func inContentTypeValueStarted() throws {
    var i = index
    let len = length
    repeat {
      let c = stream[i]
      if c == 13 {
        if let s = collectString(i) {
          contentTypeValue = s
        } else {
          throw BodyParserError.FileNameValue
        }
        entryParser = .ContentBody
        index = i + 1
        break
      } else if c > 32 { // Space.
        // ignore
      } else {
        throw BodyParserError.ContentTypeValue
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

  mutating func inMatchToken() throws {
    var i = index
    let len = length
    let shadowLasti = shadowMatch.count - 1
    repeat {
      let ci = i - tokenIndex
      if stream[i] == shadowMatch[tokenBufferEnd + ci] {
        if ci == shadowLasti {
          entryParser = linedUpParser
          index = i + 1
          tokenIndex = -1
          break
        }
      } else {
        throw BodyParserError.MatchToken
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

  mutating func inContentBody() throws {
    if stream[index] == 10 {
      index += 1
      entryParser = .ContentBodyStarted
    } else {
      throw BodyParserError.ContentBody
    }
  }

  mutating func inContentBodyStarted() throws {
    if stream[index] == 13 {
      index += 1
      entryParser = .LineFeed
      linedUpParser = .ContentData
    } else {
      throw BodyParserError.ContentBody
    }
  }

  mutating func inContentData() throws {
    tokenIndex = index
    entryParser = .ContentDataStarted
    boundaryMatch = []
    boundTest1 = false
    boundTest2 = false
    boundTest3 = false
    if !fileNameValue.isEmpty || !contentTypeValue.isEmpty {
      tempFile = try TempFile(prefix: "bodyparser", suffix: "upload")
    }
  }

  mutating func storeFile(endIndex: Int) {
    let bb = collectToken(endIndex)
    tempFile!.writeBytes(bb, maxBytes: bb.count)
    if let oldFile = body.files[nameValue] {
      (oldFile.file as! TempFile).closeAndUnlink()
    }
    body.files[nameValue] = BodyFile(name: fileNameValue,
        contentType: contentTypeValue, file: tempFile!)
    tempFile = nil
  }

  mutating func inContentDataStarted() throws {
    var i = index
    let len = length
    let blasti = boundary.count - 1
    repeat {
      let c = stream[i]
      if boundTest3 && c == 13 {
        let ei = i - boundary.count - 5
        if tempFile != nil {
          storeFile(ei)
        } else {
          body.fields[nameValue] = collectString(ei)
        }
        index = length // Body exit.
        done = true
        break
      }
      boundTest3 = false
      if boundTest2 && c == 45 {
        boundTest3 = true
      }
      boundTest2 = false
      if boundTest1 {
        if c == 13 {
          let ei = i - boundary.count - 3
          if tempFile != nil {
            storeFile(ei)
          } else {
            body.fields[nameValue] = collectString(ei)
          }
          entryParser = .LineFeed
          linedUpParser = .ContentDisposition
          index = i + 1
          break
        } else if c == 45 {
          boundTest2 = true
        }
      }
      boundTest1 = false
      if BoundaryCharTable.TABLE[c] {
        var a = [Int]()
        for j in 0..<boundaryMatch.count {
          let m = boundaryMatch[j]
          if boundary.match(m, c: c) {
            if m == blasti {
              boundTest1 = true
            } else {
              a.append(m + 1)
            }
          }
        }
        if c == 45 {
          a.append(1)
        }
        boundaryMatch = a
      }
      i += 1
    } while i < len
    if i >= len {
      index = i
    }
  }

  mutating func inSpace() throws {
    while index < length && stream[index] == 32 {
      index += 1
    }
    entryParser = linedUpParser
  }

  // Call this to help remove the temp files.
  //
  // When BodyParser is used from a main file, outside functions, temp files
  // could persist after the program has finished running.
  mutating func close() {
    for (_, bf) in body.files {
      (bf.file as! TempFile).closeAndUnlink()
    }
  }

}


enum BodyParserError: ErrorType {
  case Body
  case Key
  case Value
  case BeginMultipart
  case MatchToken
  case ContentDisposition
  case LineFeed
  case FormData
  case Name
  case NameValue
  case FileName
  case FileNameValue
  case ContentBody
  case ContentTypeValue
  case Unreachable
}
