Data Types
----------

Swift is a language of many data types. Swift even supports C types when
imported via Glibc calls. Swift types can be passed to C functions very easily.
And sometimes Swift has to deal with types resulting from these calls to C
functions.

String is one of the most important data types. It's perhaps the most user visible
one. As such, it is a good idea to make the String type well-supported by giving
it the attention it deserves. One of the ideas for the String type is to give it
the shortest method names. While Swift supports overloading based on types, it's
not always a good idea to overload methods all the time. As such, String wins
the method names that don't include types in their names as a suffix.

E.g.: IO:

  * read - This is the String one.
  * readBytes - This is the UInt8 one.
  * readCChar - This is the one for C strings compatibility.

I like the Bytes suffix for the UInt8 based methods. I think I saw some Bytes
methods in some Objective-C calls from Swift in the Swift standard libraries,
which further reinforced my opinion of it. When dealing with data, UInt8 helps
us to avoid dealing with signedness. UInt8 is also largely compatible with the
next preferred data type: CChar.

In IO code we can find methods like writeBytes for UInt8 data.

CChar is the type for dealing with C strings. I first came across it in Swift
when calling the String.fromCString method. Even though it supported an
UnsafePointer data type, I think. Let me check. Yes, fromCString takes an
UnsafePointer\<CChar\> type as parameter.

While it is possible to convert types from one kind to another sometimes
relatively easily, it may require enough mental gymnastics to make it an unwelcome
thought. As such, I still like to support those different data types when I can.
Even though I'm not sure supporting the CChar everywhere is a good idea
necessarily.

One of the problems of using the String type as a general data type is that
Swift takes Unicode very seriously for its Strings, which means that a malformed
Unicode String or some such may not work well in Swift. That's also why when
converting data to Strings, given that the conversion may fail, we have to
support the Optional String type. It ensures that if the conversion fails, the
program has a chance to recover from it somehow. Rather than silently taking
up empty or truncated Strings in case of error.

For data, dealing with data in UInt8 format may be more forgiving. It's an extra
chance to deal with data that cannot fit on a Unicode String. So let there be
the Bytes methods.

UnsafePointer<>
---------------

Swift is a lower level language. As such, it has access to things like
UnsafePointer. The name is purposefully made ugly to discourage people from
abusing that power and losing some safety as checked by the compiler. Still,
UnsafePointer is a necessary data type. It is a data type that can help us to
avoid further allocations when converting data from one type to another. And it
is compatible with dealing with data in [UInt8] or [CChar] arrays.

When dealing with multi-byte types in algorithms that are lower level by
definition, using types such as UnsafePointer and UnsafeBufferPointer helps with
the translation to Swift.

See the MurmurHash3 algorithm for an example of the types discussed above:

* [../Sources/murmurhash3.swift](../Sources/murmurhash3.swift)
* [../examples/murmur/Sources/main.swift](../examples/murmur/Sources/main.swift)
