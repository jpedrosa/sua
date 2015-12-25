File Browser
------------

Listing files is an important feature to have. With the
[FileBrowser](../Sources/file_browser.swift) now included
in Sua Swift, the code required to get it done has been reduced to a minimum:

```swift
var fb = try FileBrowser(path: "./")

while fb.next() {
  p("name: \(fb.name!), type: \(fb.type)")
}
```

The next() method call sets up the data on the entry struct returned by the call
to the readdir C function. FileBrowser calls these C functions to get things
done: opendir, readdir and closedir. It's all done behind the scenes with the
FileBrowser class.

While developing it I tested the performance in for example this [benchmark](../examples/benchmarks/track_dir/Sources/main.swift):

```
$ .build/release/TrackDir
"trackDir   count: 726484 Elapsed: 528"
"spelunkDir count: 726484 Elapsed: 613"
"browseDir  count: 726484 Elapsed: 500"
```
(Elapsed time is in milliseconds, while searching over 720k files in the entire
file system starting at "/".)

It is not that the browseDir function is necessarily faster than the trackDir
one, since the trackDir one is just a single recursive function doing all the
work, while the browseDir function calls into the FileBrowser methods. The
reason later functions can be faster than the earlier ones is that the earlier
ones help to warm up the IO calls to the operating system, which is enjoyed by
the later calls.

The trackDir and browseDir functions should be about equal as fast and they
are faster than the spelunkDir because the spelunkDir uses strings for the
paths, whereas the trackDir and browseDir ones use byte arrays for the paths.

The FileBrowser class supports strings and byte arrays for the paths and
file names. While searching the entire file system starting at "/", the
performance difference could be worth the trouble. Swift strings are full
Unicode which has a small overhead when doing quick work with system function
calls.

The FileBrowser instance allows for a lot of flexibility when inquiring about
the directory files. When you want to create your own custom searching
functions, it could be a good way to get started. There is a shortcut when just
browsing all the files recursively in a directory. You could use the scanDir or
the broader recurseDir static functions instead:

```swift
try FileBrowser.scanDir("./") { (name, type) in
  p("name: \(name), type: \(type)")
}
```

This call produces about the same result of the one in the first example,
printing file and directory names and their types whether they are file,
directory or potentially unknown.

If you would rather search with recursion, you could try something such as this one:

```swift
FileBrowser.recurseDir("./") { (name, type, path) in
  p("name: \(name), type: \(type), path: \(path)")
}
```

The recurseDir call also returns the path for reference. This is pretty quick
as well and by returning the values that are most useful while making use of
them to continue browsing, it does not waste a lot of resources at all. I found
new admiration for this function when I tried to come up with a similar one that
would use path bytes and return the FileBrowser object, but I found those to not
be worth it and to be slower than just returning what the standard recurseDir
function did already.

Detour
------

I first came up with code that has turned into this FileBrowser class while 
testing a new runtime for Dart called Fletch. In Fletch I also created a version
using the Linux getdents system call. With getdents it was slightly faster than
using the standard readdir one.

Overall I'm pretty OK with how fast the FileBrowser in Swift has become.
