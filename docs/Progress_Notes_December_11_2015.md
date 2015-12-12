Progress Notes
--------------

As of December 11, 2015, Sua has been coming along nicely. There is now a
dependency on an external sister project called CSua that is an extremely
small library at the moment, helping only to map the variadic open Linux
function: https://github.com/jpedrosa/csua_module

I tried to keep it to as few repositories as possible, while taking the package
manager's necessary requirements into consideration. To help to make the names
unique, I gave the CSua project an extended name of csua_module. The CSua is
made up of a csua.c, csua.h, CMakeLists.txt, Package.swift and module.modulemap
files only. CMake helps to build it and install the files into /usr/local for
system-wide reference by the package manager. The problem for now with external
module dependencies is that we have to keep importing them into the project
files in order to help the linker with the needed libraries. [One of the examples](../examples/file_and_io/Sources/main.swift)
now has code like this:

```swift
import Glibc
import Sua
import CSua
```

Imagine it if there were more libraries involved! I'm not complaining too much,
since in other languages we also have to import code all the time. It is just
that Swift is still rough on the edges and getting past the errors that we as
end-users help to cause can be quite daunting. One of the differences with low
level languages is that the errors can be quite opaque! Scary, in other words.
Even more so to those of us used to higher level languages. But we also get used
to it as we go. Power comes with great responsibility, as they say.

If you wanted to create your own modules and are unsure about how to get the
needed files in order, I suggest you take a look at all the Package.swift files
these projects have scattered around. You can even search on GitHub for more
examples.

When I'm developing Sua, one trick I use to speed the process up is that I use a
custom main.swift to produce an executable based on the libraries. But I don't
need to commit it to GitHub. So that the changes I keep making to it don't
pollute the repository too much. I find it better than to depend on the library
from other projects. I really don't like it when the package manager gets in the
way of quicker turnaround, so finding ways around it can be more than helpful,
while we give the time for the Swift tools to mature for open source needs.

I also use the Atom editor for Swift too. It's quite handy!

Here are some examples of code that Sua includes now:

```swift
var a: [CChar] = [72, 101, 108, 108, 111]

print(String.fromCharCodes(a))
print(String.fromCharCodes(a, start: 1, end: 3))

try File.open("/home/dewd/t_/sample.txt", mode: .R, fn: {f in p(f) })

try File.open("/home/dewd/t_/sample.txt", mode: .R,
    fn: { f in p(try! f.readLines()) })

try File.open("/home/dewd/t_/nope_new.txt", mode: .W,
    fn: {f in f.write("Heart Swift\n") })

try File.open("/home/dewd/t_/nope_new.txt", mode: .R,
    fn: {f in p(try! f.readWholeBuffer()) })

try File.open("/home/dewd/t_/nope_new.txt", mode: .R,
    fn: {f in p(try! f.read()) })

p(try! IO.readLines("/home/dewd/t_/sample.txt"))

p(try IO.writeBytes("/home/dewd/t_/many_tries.txt", bytes: a))
```

I have used code like that in Dart and Ruby. From Dart I borrowed the
String.fromCharCodes concept. And from Ruby, the File IO stuff.

I'm still trying to get used to code like ```try``` and ```try!``` I'm not sure
I like it too much. But I can't complain about the results too much, either.
Swift has proven to be quite good, and being related to the C family of tools
always helps!

Ruby always had the tradition of releasing new versions around Christmas. This
year we got our gift even earlier with Swift! Merry Xmas!

BTW, if you need help interoping with C, have a look [at this outstanding](https://github.com/apple/swift/blob/8d9ef80304d7b36e13619ea50e6e76f3ec9221ba/docs/proposals/C%20Pointer%20Interop%20Language%20Model.rst) Swift
article for some reassurance.
