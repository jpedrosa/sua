
import Glibc
import Sua
import CSua


var buf = stat()
var hey: UnsafeMutablePointer<stat>

p(buf.self)
var i = stat("/home/dewd/t_/sample.txt", &buf)
p("iiii \(i) \(buf)")

var o = Sys.stat(path: "/home/dewd/t_/sample.txt", buffer: &buf)
p("oooo \(o)")

var h = Sys.lstat(path: "/home/dewd/t_/sample.txt", buffer: &buf)
p("hhhh \(h)")

p("exists: \(File.exists(path: "/home/dewd/t_/sample.txt"))")

p("exists: \(File.exists(path: "/home/dewd/t_/nosample.txt"))")

p(buf.st_dev)

var sb = Stat()
let _ = sb.stat(path: "/home/dewd/t_/sample.txt")
p("\(sb.dev) \(sb.ino) \(sb.mode) \(sb.atime)")
p(sb)

var rd = Sys.opendir(path: "/home/dewd/t_")
p(rd)
p(rd.self) // OpaquePointer
p(rd == nil)
var gr = Sys.readdir(dirp: rd)
while gr != nil {
  p(gr!.pointee)
  var dirName = gr!.pointee.d_name
  let name = withUnsafePointer(&dirName) { (ptr) -> String in
    return String(cString: UnsafePointer<CChar>(ptr)) ?? ""
  }
  p(name)
  gr = Sys.readdir(dirp: rd)
}
p(Sys.closedir(dirp: rd))

FileBrowser.recurseDir(path: "/home/dewd/t_") { (name, type, path) in
  p("\(path)\(name)")
}
