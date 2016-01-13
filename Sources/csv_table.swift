

enum CSVTableParserEntry {
  case Header
  case HeaderExit
  case Row
  case RowExit
  case Column
  case ColumnQuoted
}


// Unicode data.
//
// The file format is like this:
//
// * The first row includes the serial number only. It is a sequencial number
// starting from 0 that helps to make the rows unique for updating and deleting.
//
// * The second row is the header row that helps to give a label to each column.
// The very first column is already labeled by default with "id".
//
// * From the third row onwards we find the actual data rows. They all start
// with the id column.
//
// * All rows should end with just the newline character(\n or 10).
//
// * All rows should include the same number of columns.
//
// * Data is in general represented in string format only. It simplifies it
// a lot and may match the use-case of users when they already have strings to
// compare the data with.
//
// * The column data follows the convention specified on this Wikipedia entry:
// https://en.wikipedia.org/wiki/Comma-separated_values
// Where columns can start with a double quote which can include within it:
//
//    ** A data comma. E.g. "Hey, ho"
//
//    ** A data newline character. E.g. "So \n it begins."
//
//    ** And even a data double quote if it is escaped with another double
//    quote. E.g. "Let's "" go"
//
public struct CSVTable {

  var _path: String
  public var serialId = 0
  var stream = ByteStream()
  var entryParser = CSVTableParserEntry.Header
  var _header = [String]()
  var columnGroup = CSVTableParserEntry.Header
  var recordExit = CSVTableParserEntry.HeaderExit
  var columnValue = ""
  var _rows = [[String]]()
  var _row = [String]()
  var unescapedColumnValue = ""

  public init(path: String) throws {
    _path = path
    try load()
  }

  mutating public func load() throws {
    var f = try File(path: _path)
    defer { f.close() }
    stream.bytes = try f.readAllBytes()
    if stream.eatWhileDigit() {
      serialId = Int(stream.collectTokenString()!)!
      if stream.eatOne(10) { // Newline
        entryParser = .Column
        _header = []
        columnGroup = .Header
        recordExit = .HeaderExit
        while !stream.isEol {
          try next()
        }

        // Be nice and check for a last row without a trailing new line
        // following it. Sometimes when manually editing a file, the last line
        // could lose its new line.
        if !_row.isEmpty {
          try inRowExit()
        }
      } else {
        throw CSVTableError.NewLine
      }
    } else {
      throw CSVTableError.SerialId
    }
  }

  mutating func next() throws {
    switch entryParser {
      case .Header:
        try inHeader()
      case .HeaderExit:
        try inHeaderExit()
      case .Row:
        try inRow()
      case .RowExit:
        try inRowExit()
      case .Column:
        try inColumn()
      case .ColumnQuoted:
        try inColumnQuoted()
    }
  }

  mutating func inHeader() throws {
    _header.append(columnValue)
    entryParser = .Column
  }

  mutating func inHeaderExit() throws {
    if header.isEmpty {
      throw CSVTableError.Header
    }
    entryParser = .Column
    columnGroup = .Row
    recordExit = .RowExit
    _row = []
  }

  mutating func inRow() throws {
    _row.append(columnValue)
    entryParser = .Column
  }

  mutating func inRowExit() throws {
    if _row.count != _header.count {
      throw CSVTableError.Row
    }
    entryParser = .Column
    _rows.append(_row)
    _row = []
  }

  func matchCommaOrNewLine(c: UInt8) -> Bool {
    return c == 44 || c == 10
  }

  mutating func inColumn() throws {
    stream.startIndex = stream.currentIndex
    if stream.eatDoubleQuote() {
      unescapedColumnValue = ""
      entryParser = .ColumnQuoted
      stream.startIndex = stream.currentIndex
    } else if stream.eatComma() {
      columnValue = ""
      entryParser = columnGroup
    } else if stream.eatUntil(matchCommaOrNewLine) {
      columnValue = stream.collectTokenString()!
      stream.eatComma()
      entryParser = columnGroup
    } else if stream.eatOne(10) {
      entryParser = recordExit
    } else {
      throw CSVTableError.Unreachable
    }
  }

  mutating func inColumnQuoted() throws {
    if stream.skipTo(34) >= 0 { // "
      if let s = stream.collectTokenString() {
        unescapedColumnValue += s
      }
      stream.eatDoubleQuote()
      stream.startIndex = stream.currentIndex
      if !stream.eatDoubleQuote() { // Ends if not an escaped quote sequence: ""
        if let s = stream.collectTokenString() {
          unescapedColumnValue += s
        }
        columnValue = unescapedColumnValue
        stream.eatComma()
        entryParser = columnGroup
      }
    } else {
      throw CSVTableError.Column
    }
  }

  public var path: String { return _path }

  public var header: [String] { return _header }

  public var rows: [[String]] { return _rows }

  // Don't include the id, since it will be automatically generated based on the
  // next number on the sequence.
  mutating public func insert(row: [String]) throws -> Int {
    if row.count + 1 != header.count {
      throw CSVTableError.Insert
    }
    var a = [String]()
    let sid = serialId
    a.append("\(sid)")
    for s in row {
      a.append(s)
    }
    _rows.append(a)
    serialId += 1
    return sid
  }

  // Alias for insert.
  mutating public func append(row: [String]) throws -> Int {
    return try insert(row)
  }

  // This will insert it if it does not exist, and it will keep whatever index
  // id it was called with. This can help with data migration. The serialId
  // can be adjusted accordingly afterwards.
  mutating public func update(index: String, row: [String]) throws {
    if row.count + 1 != header.count {
      throw CSVTableError.Update
    }
    let n = findIndex(index)
    if n >= 0 {
      for i in 0..<row.count {
        _rows[n][i + 1] = row[i]
      }
    } else {
      var a = [String]()
      a.append(index)
      for s in row {
        a.append(s)
      }
      _rows.append(a)
    }
  }

  func findIndex(index: String) -> Int {
    for i in 0..<_rows.count {
      if _rows[i][0] == index {
        return i
      }
    }
    return -1
  }

  // If the record pointed at by index does not exist, simply ignore it.
  mutating public func delete(index: String) {
    let n = findIndex(index)
    if n >= 0 {
      _rows.removeAtIndex(n)
    }
  }

  mutating public func updateColumn(index: String, columnIndex: Int,
        value: String) {
    let n = findIndex(index)
    if n >= 0 {
      _rows[n][columnIndex] = value
    }
  }

  mutating public func select(index: String) -> [String]? {
    let n = findIndex(index)
    if n >= 0 {
      return _rows[n]
    }
    return nil
  }

  public var data: String {
    var s = "\(serialId)\n"
    var comma = false
    for c in _header {
      if comma { s += "," }
      s += CSVTable.escape(c)
      comma = true
    }
    s += "\n"
    if !_rows.isEmpty {
      for row in _rows {
        var comma = false
        for c in row {
          if comma { s += "," }
          s += CSVTable.escape(c)
          comma = true
        }
        s += "\n"
      }
      s += "\n"
    }
    return s
  }

  public func save() throws {
    try IO.write(path, string: data)
  }

  // This makes sure the data is escaped for double quote, comma and new line.
  public static func escape(string: String) -> String {
    let len = string.utf16.count
    var i = 0
    while i < len {
      let c = string.utf16.codeUnitAt(i)
      if c == 34 || c == 44 || c == 10 { // " , newline
        i += 1
        var s = "\""
        s += string.utf16.substring(0, endIndex: i) ?? ""
        if c == 34 {
          s += "\""
        }
        var si = i
        while i < len {
          if string.utf16.codeUnitAt(i) == 34 {
            s += string.utf16.substring(si, endIndex: i + 1) ?? ""
            s += "\""
            si = i + 1
          }
          i += 1
        }
        s += string.utf16.substring(si, endIndex: i) ?? ""
        s += "\""
        return s
      }
      i += 1
    }
    return string
  }

  public static func create(path: String, header: [String]) throws -> CSVTable {
    var s = "0\nid"
    for c in header {
      s += ","
      s += escape(c)
    }
    s += "\n"
    try IO.write(path, string: s)
    return try CSVTable(path: path)
  }

}


enum CSVTableError: ErrorType {
  case SerialId
  case NewLine
  case Header
  case Row
  case Column
  case Insert
  case Update
  case Unreachable
}
