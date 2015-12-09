
func escapeString(s: String) -> String {
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

func inspect(o: String) -> String {
  return escapeString(o)
}

func inspect(o: Int) -> String {
  return String(o)
}

func inspect(o: CustomStringConvertible) -> String {
  return o.description
}

func inspect(o: Any?) -> String {
  return String(o)
}

func p(a: String...) {
  for e in a {
    print(inspect(e))
  }
}

func p(a: Any?...) {
  for e in a {
    print(e)
  }
}

func p(a: CustomStringConvertible...) {
  for e in a {
    print(e)
  }
}
