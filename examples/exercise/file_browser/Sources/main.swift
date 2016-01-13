
import Glibc
import CSua
import Sua


func printFileContent(path: String) throws {
  let a = try IO.readAllBytes(path)
  Stdout.writeBytes(a, maxBytes: a.count)
}

func printDirectoryEntries(path: String) throws {
  print("Directory listing of \u{1b}[34m\(path)\u{1b}[0m")
  print("Type F/\u{1b}[34mD\u{1b}[0m: Name")
  var a = [(String, FileType)]()
  try FileBrowser.scanDir(path) { name, type in
    if name != "." && name != ".." {
      a.append((name, type))
    }
  }
  a.sortInPlace {
    let (name1, t1) = $0
    let (name2, t2) = $1
    if t1 == .D {
      if t2 == .D {
        return name1 < name2
      } else {
        return true
      }
    } else if t2 == .D {
      return false
    } else {
      return name1 < name2
    }
  }
  for e in a {
    let (name, t) = e
    switch t {
      case .D: print("\u{1b}[34m  D     : \(name)\u{1b}[0m")
      case .F: print("  F     : \(name)")
      case .U: print("\u{1b}[31m  U     : \(name)\u{1b}[0m")
    }
  }
}

func error(path: String) {
  print("\u{1b}[1m\u{1b}[31mError\u{1b}[0m: Invalid file or directory " +
      "argument: \(path)")
}

let args = Process.arguments
let len = args.count
if len == 2 {
  let path = args[1]
  if let st = File.stat(path) {
    if st.isRegularFile {
      try printFileContent(path)
    } else if st.isDirectory {
      try printDirectoryEntries(path)
    } else {
      error(path)
    }
  } else {
    error(path)
  }
} else {
  if len > 2 {
    print("\u{1b}[1m\u{1b}[31mError\u{1b}[0m: Too many arguments. The " +
        "command takes at most 1 argument.\n")
  }
  print("Usage: give the command a file or directory path and it will either " +
      "print the content of the file or list the entries of the directory.")
}
