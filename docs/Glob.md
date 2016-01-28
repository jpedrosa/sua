Glob and File Path
------------------

Sua gets support for Glob features at last! I had expected to be able to do it
since I started the Sua project, as I think that Swift is a good candidate for
both server and command-line tools.

Now, see this sample code:

```swift
for (name, type, path) in Dir["/home/dewd/t_/**/*.txt"] {
  print("\(type):\(path)\(name)")
}
```

The Dir subscript method seen above returns a tuple with those values for name,
type and path. I have seen it in other languages that when they return just a
single string including both path and name that then users may need to parse
that to extract the name or actual path or even to do another stat call to be
able to tell whether it's a file or directory.

Another way to approach the problem is by instantiating
[FileGlobList](../Sources/file_glob.swift) like this:

```swift
var list = try FileGlobList(pattern: "/home/dewd/t_/s*/*") { name, type, path in
  print("\(path)\(name)")
}

try list.list()
```

This second version provides for a bit of more control. Errors could be
propagated with this second version and ignoreCase could be configured via the
constructor parameter, like this:

```swift
var list = try FileGlobList(pattern: "/home/dewd/t_/s*/*", skipDotFiles: false,
    ignoreCase: true) { name, type, path in
  print("\(path)\(name)")
}

try list.list()
```

I was nearly forgetting to mention the skipDotFiles feature. It's kind of a
standard on Unix tools that when they have glob features, especially on the
shell, that they should skip files that have names starting with a dot
character. The lore is that this became a feature that grew out of a bug, since
the developer had originally meant to skip only the files "." and ".." that are
meta files that are largely unimportant, but then folks took advantage of it and
started naming the files that were to be ignored by default with a leading dot
character.

The ignoreCase feature actually just converts the related characters to lower
case when matching them with. And at this point, it's only the ASCII characters,
since full support for Unicode is kind of complicated and can slow down the
algorithms even further and we'd have to depend on other libraries in order to
get it going. (Excuses!) :-)

While matching glob against file and directory names is the most important
use-case of glob, one could also reuse the library for other needs, by calling
the basic comparison API like this:

```swift
var g = try Glob.parse("hello*.txt")
print(g.match("hello_world.txt")) // Prints true.
```

To make a general [Glob](../Sources/glob.swift) pattern matcher like that was a
request that I got when I originally created the code in Dart, before converting
it to Swift. After some thinking and tribulations during the conversion, I
finally got it done!

I had to come up with other supporting classes in the interim, such as the
common [Lexer](../Sources/lexer.swift) features that were also first an idea in
Dart. I also brought over to Swift some of the [File.join, File.baseName and
even File.expandName](../Sources/file.swift#L400) that were originally ideas
from Ruby.

```swift
print(try File.expandPath("~/t_"))          // Prints /home/dewd/t_
// The following prints: /home/dewd/t_/swift
print(try File.expandPath(File.join("~/t_", "swift")))
print(File.extName("some.png"))            // Prints .png
print(File.baseName("../t_/some.png"))     // Prints some.png
```

Performance-wise, Ruby's globbing is still faster, like in some of the examples
I ran, Ruby would finish in about 170ms and my version in Swift would finish in
about 240ms. That's a broad picture. Now that I think about it, perhaps the Ruby
version felt even faster because Ruby would buffer more of the computations,
whereas my algorithms were doing the computations at the same time that they
were printing the results, so between lines it felt a little more sluggish. It
is possible that Ruby's version can be even twice as fast, since Ruby is calling
into C a lot and that's an area that Ruby excels at. And my code is calling into
a fair bunch of abstractions in order to help to exercise them, like the
[ByteMatcher](../Sources/byte_matcher.swift),
[ByteStream](../Sources/byte_stream.swift), [GlobLexer](../Sources/glob.swift)
and on and on... :-)

I had some fun around Swift's protocols. I even decided against using protocols
when I could have used them to extend the Array type to add some
asciiToLowerCase methods. Luckily, I chose instead to use a custom
[class](../Sources/ascii.swift) for that. With the class the code was less
complicated, with less generics to worry about.

I'm not particularly proud of all of the code that I had to come up with to make
FileGlobList possible. While I can think about alternatives, I really don't care
to give them a try. The code got some clean up during the move from Dart to
Swift which I'm happy enough about. Some variable names got longer now, more
descriptive, as I had to remember what they did. :-)

That reminded me that since Swift is more concise, with fewer punctuations due
to cases like optional parentheses, that we could make up for it with longer
variable names instead. :-)

In truth, Swift is not always concise. In dealing with types, we can create a
ton structs and protocols and stuff that in other languages would not be needed
as they would reuse more of their standard data structures instead. That's the
bittersweet side of Swift. Still, I was thinking that perhaps Swift is the
closest to the bare-metal that most programmers will ever get. A lot of the
stuff that we learned for Assembly, C, and so on, can be put to good use with
Swift. And yet, many of us would never be as productive in a lower-level
language as we can be in Swift.

And a table of the Glob features that are supported:

   * The ? wildcard - It will match a single character of any kind.

   * The * wildcard - It will match any character until the next pattern is
                      found.
   * The [a-z] [abc] [A-Za-z0-9_] character set - It will match a character
                      included in its ranges or sets.
   * The [!a-z] [!def] character set negation. It will match a character
                      that is not included in the set.
   * The {jpg,png} optional names - It will match one of the names included
                      in its list.

**Note** The special characters could be escaped with the \ backslash character
in order to allow them to work like any other character.

```swift
for (name, type, path) in Dir["/home/dewd/**/*{.png,.jpg}"] {
  print("\(type):\(path)\(name)")
}
```

The example above would search for the files ending in either .png or .jpg
extension in the given directories, recursively.

**Edit:** Added an actual example to the repository:
[GlobList.](../examples/glob_list/Sources/main.swift)

Cheers!
