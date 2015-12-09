
public func escapeString(s: String) -> String {
  var z = ""
  debugPrint(s, terminator: "", toStream: &z)
  return z
}

public func inspect(o: Any) -> String {
  var z = ""
  debugPrint(o, terminator: "", toStream: &z)
  return z
}

public func p(a: Any...) {
  for e in a {
    debugPrint(e)
  }
}
