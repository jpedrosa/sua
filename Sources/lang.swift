
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

// printList is like the "puts" command in Ruby.
// printList will check whether the line ends with a new line, and if it does
// not, it will append a new line to it.
// It will also print the individual items of arrays and variadic parameters on
// separate lines.
// Since importing Glibc already imports the "puts" command found in C which
// would conflict with this command, we've given it a unique name instead.
public func printList(string: String) {
  // 10 - new line
  if string.isEmpty || string.utf16.codeUnitAt(string.utf16.count - 1) != 10 {
    print(string)
  } else {
    Stdout.write(string)
  }
}

public func printList(strings: [String]) {
  for s in strings {
    printList(s)
  }
}

public func printList(bunch: [Any]) {
  for o in bunch {
    printList("\(o)")
  }
}

public func printList(list: Any...) {
  for v in list {
    printList("\(v)")
  }
}
