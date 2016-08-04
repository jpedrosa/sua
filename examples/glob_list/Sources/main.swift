
import Glibc
import Sua


func printUsage() {
  print("GlobList: GlobList <pattern>\n" +
      "Where the pattern follows a Glob pattern, including a directory path\n" +
      "that may include a recursion command.\n" +
      "E.g. GlobList \"~/**/*.txt\"\n\n" +
      "**Note** It's best to enclose the pattern within quotes, so that the\n" +
      "         shell does not try to interpret it itself.\n\n" +
      "Table of supported Glob features:\n" +
      "    * The ? wildcard - It will match a single character of any kind.\n" +
      "\n" +
      "    * The * wildcard - It will match any character until the next\n" +
      "                       pattern is found.\n" +
      "    * The [a-z] [abc] [A-Za-z0-9_] character set - It will match a\n" +
      "                       character included in its ranges or sets.\n" +
      "    * The [!a-z] [!def] character set negation. It will match a\n" +
      "                       character that is not included in the set.\n" +
      "    * The {jpg,png} optional names - It will match one of the names\n" +
      "                       included in its list.\n\n" +
      "The special characters could be escaped with the \\ backslash\n" +
      "character in order to allow them to work like any other character.")
}

func parseOpt() -> String? {
  return Process.arguments.count > 1 ? Process.arguments[1] : nil
}


if let s = parseOpt() {
  var z = s
  if s.utf16[0] == 126 { // ~
    z = try File.expandPath(path: s)
  }
  try Dir.glob(pattern: z) { name, type, path in
    print("\(type): \(path)\(name)")
  }
} else {
  printUsage()
}
