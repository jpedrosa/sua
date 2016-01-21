

public protocol Tokenizer { }


public protocol TokenType { }


public protocol LexerToken {
  var bytes: [UInt8] { get }
  var startIndex: Int { get }
  var endIndex: Int { get }
  var type: TokenType { get }
  var string: String { get }
  func collect() -> [UInt8]
}


protocol Lexer {

  var stream: ByteStream { get }

  func parse(fn: (type: TokenType) throws -> Void) throws

  func parseTokenStrings(
      fn: (type: TokenType, string: String) throws -> Void) throws

  func parseTokens(fn: (token: LexerToken) throws -> Void) throws

}


public struct CommonLexerStatus {

  public var lineCount = 0
  public var newLineKeyword: TokenType?
  public var lineStartIndex = 0
  public var tokenizer: Tokenizer?
  public var spaceTokenizer: Tokenizer?

  init(tokenizer: Tokenizer?) {
    lineCount = 0
    newLineKeyword = nil
    lineStartIndex = 0
    self.tokenizer = tokenizer
    spaceTokenizer = nil
  }

}


extension LexerToken {

  public var string: String {
    if let s = String.fromCharCodes(bytes, start: startIndex,
        end: endIndex - 1) {
      return s
    }
    return ""
  }

  public func collect() -> [UInt8] {
    return Array(bytes[startIndex..<endIndex])
  }

  public func collectString() -> String? {
    return String.fromCharCodes(bytes, start: startIndex, end: endIndex - 1)
  }

  public var description: String {
    return "CommonToken(startIndex: \(startIndex), endIndex: \(endIndex), " +
        "type: \(type), string: \(inspect(string)))"
  }

}


public struct CommonToken: LexerToken, CustomStringConvertible {

  public var bytes: [UInt8]
  public var startIndex: Int
  public var endIndex: Int
  public var type: TokenType

}


public class CommonLexer: Lexer, CustomStringConvertible {

  public var stream: ByteStream
  var status: CommonLexerStatus

  init(bytes: [UInt8], status: CommonLexerStatus) {
    stream = ByteStream(bytes: bytes)
    self.status = status
  }

  // Override me.
  func next(tokenizer: Tokenizer) -> TokenType? {
    return nil
  }

  func parseLine(fn: (type: TokenType) throws -> Void) throws {
    status.lineCount += 1
    while !stream.isEol {
      var tt: TokenType?
      if let st = status.spaceTokenizer {
        tt = next(st)
      }
      if tt == nil {
        if let t = status.tokenizer {
          tt = next(t)
        }
      }
      //p([stream.currentTokenString, status.tokenizer]);
      //p(status.stored);
      if let t = tt {
        if stream.startIndex != stream.currentIndex {
          try fn(type: t)
        }
      } else {
        throw CommonLexerError.TokenType
      }
      stream.startIndex = stream.currentIndex
    }
    //p(status.indent);
  }

  func parseTokenStrings(fn: (type: TokenType, string: String) throws -> Void)
      throws {
    try parse() { tt in
      if let s = self.stream.currentTokenString {
        try fn(type: tt, string: s)
      } else {
        throw CommonLexerError.String
      }
    }
  }

  func parse(fn: (type: TokenType) throws -> Void) throws {
    let len = stream.bytes.count
    var ninc = 0
    var haveNewLine = false
    let newLineKey = status.newLineKeyword
    let haveNewLineKey = newLineKey != nil
    var si = 0
    repeat {
      var i = stream.findIndex(UInt8(10), startAt: si)
      haveNewLine = i >= 0
      if !haveNewLine {
        i = len
      } else if i > 0 && stream.bytes[i - 1] == 13 {
        // CR. Handle crlf newline.
        i -= 1
        ninc = 2
      } else {
        ninc = 1
      }
      if i - si > 0 {
        stream.lineEndIndex = i
        try parseLine(fn)
        if stream.currentIndex >= len {
          break
        }
        if haveNewLineKey && haveNewLine {
          stream.startIndex = i
          stream.currentIndex = i + ninc
          try fn(type: newLineKey!)
        }
      } else {
        if haveNewLineKey && haveNewLine {
          stream.startIndex = i
          stream.currentIndex = i + ninc
          try fn(type: newLineKey!)
        }
        status.lineCount += 1
      }
      si = i + ninc
      stream.startIndex = si
      stream.currentIndex = si
      status.lineStartIndex = si
      } while si < len
  }

  func parseTokens(fn: (token: LexerToken) throws -> Void) throws {
    try parse() { tt in
      try fn(token: CommonToken(bytes: self.stream.bytes,
            startIndex: self.stream.startIndex,
            endIndex: self.stream.currentIndex,
            type: tt))
    }
  }

  func parseAllTokens() throws -> [CommonToken] {
    var a = [CommonToken]()
    try parse() { tt in
      a.append(CommonToken(bytes: self.stream.bytes,
            startIndex: self.stream.startIndex,
            endIndex: self.stream.currentIndex,
            type: tt))
    }
    return a
  }

  public var description: String {
    return "CommonLexer(status: \(status))"
  }

}


enum CommonLexerError: ErrorType {
  case TokenType
  case String
}
