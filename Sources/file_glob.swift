

public enum FileGlobTokenizer: Tokenizer {
  case OptionalNameComma
  case OptionalName
  case OptionalNameMaybeEmpty
  case SetChar
  case SetClose
  case SetMinusChar
  case SetLowerCaseMinus
  case SetUpperCaseMinus
  case SetDigitMinus
  case Set
  case SetCharMaybeEmpty
  case SetNegation
  case SetMaybeEmpty
  case Body
  case Root
  case Text
}


enum FileGlobTokenType: TokenType {
  case Text
  case Separator
  case Name
  case Symbol
  case SymAsterisk           // *
  case SymQuestionMark       // ?
  case SymCircumflex         // ^
  case SetChar               // Second part of [a-b] It's "b".
  case SetLowerChar
  case SetUpperChar
  case SetDigitChar
  case SymOBSet              // [
  case SymMinusSet           // -
  case SymCBSet              // ]
  case OptionalName
  case SymOBOptionalName     // {
  case SymCommaOptionalName  // ,
  case SymCBOptionalName     // }
}


class FileGlobLexer: CommonLexer {

  typealias T = FileGlobTokenizer

  init(bytes: [UInt8]) {
    super.init(bytes: bytes, status: CommonLexerStatus(tokenizer: T.Root))
  }

  override func next(tokenizer: Tokenizer) -> TokenType {
    switch(tokenizer as! FileGlobTokenizer) {
      case .OptionalNameComma:
        return inOptionalNameComma()
      case .OptionalName:
        return inOptionalName()
      case .OptionalNameMaybeEmpty:
        return inOptionalNameMaybeEmpty()
      case .SetChar:
        return inSetChar()
      case .SetClose:
        return inSetClose()
      case .SetMinusChar:
        return inSetMinusChar()
      case .SetLowerCaseMinus:
        return inSetLowerCaseMinus()
      case .SetUpperCaseMinus:
        return inSetUpperCaseMinus()
      case .SetDigitMinus:
        return inSetDigitMinus()
      case .Set:
        return inSet()
      case .SetCharMaybeEmpty:
        return inSetCharMaybeEmpty()
      case .SetNegation:
        return inSetNegation()
      case .SetMaybeEmpty:
        return inSetMaybeEmpty()
      case .Body:
        return inBody()
      case .Root:
        return inRoot()
      case .Text:
        return inText()
    }
  }

  func isContextChar(c: UInt8) -> Bool {
    return c == 47 || c == 42 || c == 63 || c == 123 || c == 91 // / * ? { [
  }

  func inOptionalNameComma() -> FileGlobTokenType {
    if stream.eatComma() {
      status.tokenizer = T.OptionalName
      return .SymCommaOptionalName
    } else if stream.eatCloseBrace() {
      status.tokenizer = T.Body
      return .SymCBOptionalName
    }
    return inText()
  }

  func inOptionalName() -> FileGlobTokenType {
    if stream.eatWhileNeitherTwo(125, c2: 44) { // } ,
      status.tokenizer = T.OptionalNameComma
      return .OptionalName
    }
    return inText()
  }

  func inOptionalNameMaybeEmpty() -> FileGlobTokenType {
    if stream.eatCloseBrace() {
      status.tokenizer = T.Body
      return .SymCBOptionalName
    }
    return inOptionalName()
  }

  func inSetChar() -> FileGlobTokenType {
    if stream.eatCloseBracket() {
      status.tokenizer = T.Body
      return .SymCBSet
    } else if stream.eatSlash() {
      status.tokenizer = T.Body
      return .Separator
    }
    stream.eatWhileNeitherTwo(93, c2: 47) // ] /
    return .SetChar
  }

  func inSetClose() -> FileGlobTokenType {
    stream.eatCloseBracket()
    status.tokenizer = T.Body
    return .SymCBSet
  }

  func inSetMinusChar() -> FileGlobTokenType {
    stream.next()
    status.tokenizer = T.Set
    return .SetChar
  }

  func inSetLowerCaseMinus() -> FileGlobTokenType {
    stream.eatMinus()
    if stream.matchLowerCase() >= 0 {
      status.tokenizer = T.SetMinusChar
      return .SymMinusSet
    } else if stream.matchCloseBracket() {
      status.tokenizer = T.SetClose
      return .SetChar
    }
    return inText()
  }

  func inSetUpperCaseMinus() -> FileGlobTokenType {
    stream.eatMinus()
    if stream.matchUpperCase() >= 0 {
      status.tokenizer = T.SetMinusChar
      return .SymMinusSet
    } else if stream.matchCloseBracket() {
      status.tokenizer = T.SetClose
      return .SetChar
    }
    return inText()
  }

  func inSetDigitMinus() -> FileGlobTokenType {
    stream.eatMinus()
    if stream.matchDigit() >= 0 {
      status.tokenizer = T.SetMinusChar
      return .SymMinusSet
    } else if stream.matchCloseBracket() {
      status.tokenizer = T.SetClose
      return .SetChar
    }
    return inText()
  }

  func handleFirstSetChar(t: Tokenizer, type: FileGlobTokenType)
      -> FileGlobTokenType {
    if stream.matchMinus() {
      status.tokenizer = t
      return type
    } else if stream.matchCloseBracket() {
      status.tokenizer = T.SetClose
      return .SetChar
    }
    status.tokenizer = T.SetChar
    return .SetChar
  }

  func inSet() -> FileGlobTokenType {
    status.tokenizer = T.Set
    if stream.eatCloseBracket() {
      status.tokenizer = T.Body
      return .SymCBSet
    } else if stream.eatLowerCase() {
      return handleFirstSetChar(T.SetLowerCaseMinus, type: .SetLowerChar)
    } else if stream.eatUpperCase() {
      return handleFirstSetChar(T.SetUpperCaseMinus, type: .SetUpperChar)
    } else if stream.eatDigit() {
      return handleFirstSetChar(T.SetDigitMinus, type: .SetDigitChar)
    } else if stream.next() != nil {
      return .Name
    }
    return inText()
  }

  func inSetCharMaybeEmpty() -> FileGlobTokenType {
    if stream.eatCloseBracket() {
      return inText()
    }
    return inSet()
  }

  func inSetNegation() -> FileGlobTokenType {
    if stream.eatCircumflex() {
      status.tokenizer = T.Set
      return .SymCircumflex
    }
    return inSetCharMaybeEmpty()
  }

  func inSetMaybeEmpty() -> FileGlobTokenType {
    if stream.eatCloseBracket() {
      return inText()
    }
    return inSetNegation()
  }

  func inBody() -> FileGlobTokenType {
    if stream.eatSlash() {
      return .Separator
    } else if stream.eatAsterisk() {
      stream.eatAsterisk()
      return .SymAsterisk
    } else if stream.eatQuestionMark() {
      return .SymQuestionMark
    } else if stream.eatOpenBrace() {
      status.tokenizer = T.OptionalNameMaybeEmpty
      return .SymOBOptionalName
    } else if stream.eatOpenBracket() {
      status.tokenizer = T.SetMaybeEmpty
      return .SymOBSet
    }
    stream.eatUntil(isContextChar)
    return .Name
  }

  func inRoot() -> FileGlobTokenType {
    status.tokenizer = T.Body
    if stream.eatSlash() {
      return .Separator
    }
    return inBody()
  }

  func inText() -> FileGlobTokenType {
    stream.skipToEnd()
    status.tokenizer = T.Text
    return .Text
  }

}
