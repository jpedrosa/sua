
import Glibc
import Sua
import CSua


p("let's go")

let fd = try Sys.openFile("/home/dewd/t_/sample.txt")

p("fd", fd)

var z = [CChar](count: 1024, repeatedValue: 0)

let r = Sys.read(fd, address: &z, length: 1023)

p(z)

p(String.fromCString(&z) ?? "")

var range = z[2..<4]

p(range)

var b = [CChar](range)

b.append(0)

p(b)

p(String.fromCString(&b) ?? "")

p(String.fromCharCodes(z))

p(String.fromCharCodes(z, start: 2, end: 4))

p(String.fromCharCodes(z, start: 2))

p(String.fromCharCodes(z, start: 3, end: -1))

var a: [CChar] = [72, 101, 108, 108, 111]

print(String.fromCharCodes(a))
print(String.fromCharCodes(a, start: 1, end: 3))

p(PosixSys.SEEK_SET)

p(Sys.lseek(fd, offset: 0, whence: PosixSys.SEEK_END))

p(Sys.rename("/home/dewd/t_/aaa.txt", newPath: "/home/dewd/t_/bbb.txt"))

p(Sys.unlink("/home/dewd/t_/yuyu.txt"))

p(Sys.getcwd())

let wfd = try Sys.openFile("/home/dewd/t_/newspaper.txt", operation: "w")

var sample: [CChar] = "sayugara".utf8.map { CChar($0) }

p(Sys.write(wfd, address: &sample, length: sample.count))

p(Sys.writeString(wfd, string: "hello"))

try File.open("/home/dewd/t_/sample.txt", mode: "r", fn: {f in p(f) })

try File.open("/home/dewd/t_/sample.txt", mode: "r",
    fn: { f in p(try! f.readLines()) })

try File.open("/home/dewd/t_/sample.txt", mode: "r", fn: {f in p(f.length) })

try File.open("/home/dewd/t_/nope_new.txt", mode: "w",
    fn: {f in f.write("Heart Swift\n") })

try File.open("/home/dewd/t_/nope_new.txt", mode: "r",
    fn: {f in p(try! f.readWholeBuffer()) })

try File.open("/home/dewd/t_/nope_new.txt", mode: "r",
    fn: {f in p(try! f.read()) })

p(try! IO.readLines("/home/dewd/t_/sample.txt"))

p(try IO.writeBytes("/home/dewd/t_/many_tries.txt", bytes: a))
