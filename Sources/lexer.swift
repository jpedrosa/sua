

public protocol LexerByteStream {
  var bytes: [UInt8] { get }
  var startIndex: Int { get set }
  var currentIndex: Int { get set }
  var isEol: Bool { get }
  var currentTokenString: String? { get }
  var lineEndIndex: Int { get set }
  func findIndex(c: UInt8, startAt: Int) -> Int
}


extension ByteStream: LexerByteStream { }


public protocol LexerStatus {
  var defaultTokenizer: LexerTokenizer? { get set }
  var lineCount: Int { get set }
  var newLineKeyword: TokenType? { get set }
  var lineStartIndex: Int { get set }
  var tokenizer: LexerTokenizer? { get set }
  var spaceTokenizer: LexerTokenizer? { get set }
}


public protocol LexerTokenizer { }


public protocol TokenType { }


protocol Lexer {

  var stream: LexerByteStream { get }
  var status: LexerStatus { get }
  var lineCount: Int { get set }
  var lineStartIndex: Int { get set }
  var newLineKeyword: Int { get }

  init(stream: LexerByteStream)

  func next(entry: LexerTokenizer) -> TokenType?

  func parse(fn: (type: TokenType) throws -> Void) throws

  func parseTokenStrings(
      fn: (type: TokenType, string: String) throws -> Void) throws

}


public struct CommonLexerStatus: LexerStatus {

  public var defaultTokenizer: LexerTokenizer?
  public var lineCount = 0
  public var newLineKeyword: TokenType?
  public var lineStartIndex = 0
  public var tokenizer: LexerTokenizer?
  public var spaceTokenizer: LexerTokenizer?

  init(tokenizer: LexerTokenizer?) {
    defaultTokenizer = nil
    lineCount = 0
    newLineKeyword = nil
    lineStartIndex = 0
    self.tokenizer = tokenizer
    spaceTokenizer = nil
  }

}


// public struct StoreLexerStatus: LexerStatus {
//
//   public var tokenizer: LexerTokenizer?
//   public var spaceTokenizer: LexerTokenizer?
//   var stored: [LexerTokenizer] = []
//   var indent = 0
//
//   init(tokenizer: LexerTokenizer? = nil,
//       spaceTokenizer: LexerTokenizer? = nil) {
//     self.tokenizer = tokenizer
//     self.spaceTokenizer = spaceTokenizer
//   }
//
//   func clone() -> StoreLexerStatus {
//     var o = StoreLexerStatus(tokenizer: tokenizer,
//         spaceTokenizer: spaceTokenizer)
//     o.indent = indent
//     for t in stored {
//       o.stored.append(t)
//     }
//     return o
//   }
//
//   mutating func push(t: LexerTokenizer) {
//     stored.append(t)
//   }
//
//   mutating func pop() -> LexerTokenizer { return stored.removeLast() }
//
//   mutating func unshift(e: LexerTokenizer) {
//     stored.insert(e, atIndex: 0)
//   }
//
//   mutating func shift() -> LexerTokenizer {
//     return stored.removeAtIndex(0)
//   }
//
// }
//
//
// func ==(lhs: StoreLexerStatus, rhs: StoreLexerStatus) -> Bool {
//   return "\(lhs.tokenizer)" == "\(rhs.tokenizer)" &&
//       lhs.indent == rhs.indent &&
//       "\(lhs.spaceTokenizer)" == "\(rhs.spaceTokenizer)" &&
//       (lhs.stored.count == rhs.stored.count &&
//         "a\(lhs.stored)" == "\(rhs.stored)")
// }


public class CommonLexer: CustomStringConvertible {

  var stream: ByteStream
  var status: CommonLexerStatus

  init(stream: ByteStream) {
    self.stream = stream
    self.status = CommonLexerStatus(tokenizer: nil)
  }

  init(stream: ByteStream, status: CommonLexerStatus) {
    self.stream = stream
    self.status = status
  }

  // Override me.
  func next(tokenizer: LexerTokenizer) -> TokenType? {
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
