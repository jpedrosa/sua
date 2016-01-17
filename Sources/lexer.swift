

public protocol Tokenizer { }


public protocol TokenType { }


protocol Lexer {

  func next(entry: Tokenizer) -> TokenType?

  func parse(fn: (type: TokenType) throws -> Void) throws

  func parseTokenStrings(
      fn: (type: TokenType, string: String) throws -> Void) throws

}


public struct CommonLexerStatus {

  public var defaultTokenizer: Tokenizer?
  public var lineCount = 0
  public var newLineKeyword: TokenType?
  public var lineStartIndex = 0
  public var tokenizer: Tokenizer?
  public var spaceTokenizer: Tokenizer?

  init(tokenizer: Tokenizer?) {
    defaultTokenizer = nil
    lineCount = 0
    newLineKeyword = nil
    lineStartIndex = 0
    self.tokenizer = tokenizer
    spaceTokenizer = nil
  }

}


public class CommonLexer: CustomStringConvertible {

  var stream: ByteStream
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
          if tt == nil {
            if let dt = status.defaultTokenizer {
              status.tokenizer = dt
              tt = next(dt)
            }
          }
        }
      }
      //p([stream.currentTokenString, status.tokenizer]);
      //p(status.stored);
      if let t = tt {
        try fn(type: t)
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
        return try fn(type: tt, string: s)
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

  public var description: String {
    return "CommonLexer(status: \(status))"
  }

}


enum CommonLexerError: ErrorType {
  case TokenType
  case String
}
