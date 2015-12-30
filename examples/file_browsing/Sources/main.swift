
import Glibc
import Sua
import CSua


var buf = stat()
var hey: UnsafeMutablePointer<stat>

p(buf.self)
var i = stat("/home/dewd/t_/sample.txt", &buf)
p("iiii \(i) \(buf)")

var o = Sys.stat("/home/dewd/t_/sample.txt", buffer: &buf)
p("oooo \(o)")

var h = Sys.lstat("/home/dewd/t_/sample.txt", buffer: &buf)
p("hhhh \(h)")

p("exists: \(File.exists("/home/dewd/t_/sample.txt"))")

p("exists: \(File.exists("/home/dewd/t_/nosample.txt"))")

p(buf.st_dev)

var sb = Stat()
sb.stat("/home/dewd/t_/sample.txt")
p("\(sb.dev) \(sb.ino) \(sb.mode) \(sb.atime)")
p(sb)

var rd = Sys.opendir("/home/dewd/t_")
p(rd)
p(rd.self) // COpaquePointer
p(rd == nil)
var gr = Sys.readdir(rd)
while gr != nil {
  p(gr.memory)
  var dirName = gr.memory.d_name
  let name = withUnsafePointer(&dirName) { (ptr) -> String in
    return String.fromCString(UnsafePointer<CChar>(ptr)) ?? ""
  }
  p(name)
  gr = Sys.readdir(rd)
}
p(Sys.closedir(rd))

FileBrowser.recurseDir("/home/dewd/t_") { (name, type, path) in
  p("\(path)\(name)")
}
