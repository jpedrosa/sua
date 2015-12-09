
public func escapeString(s: String) -> String {
  var z = ""
  for c in s.characters {
    if c == "\n" {
      z += "\\n"
    } else if c == "\"" {
      z += "\\\""
    } else if c == "\\" {
      z += "\\\\"
    } else {
      z.append(c)
    }
  }
  return "\"\(z)\""
}

public func inspect(o: String) -> String {
  return escapeString(o)
}

public func inspect(o: Int) -> String {
  return String(o)
}

public func inspect(o: CustomStringConvertible) -> String {
  return o.description
}

public func inspect(o: Any?) -> String {
  return String(o)
}

public func p(a: String...) {
  for e in a {
    print(inspect(e))
  }
}

public func p(a: Any?...) {
  for e in a {
    print(e)
  }
}

public func p(a: CustomStringConvertible...) {
  for e in a {
    print(e)
  }
}
