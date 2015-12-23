String Extensions
-----------------

Swift allows us to extend all kinds of types. String is one of the early
candidates for extensions and it was the first one that I actually extended with
the fromCharCodes methods.

Today I added to those by giving the String a
[splitOnce](../Sources/string.swift#L82) method. The inspiration
for this method came from having to split the key/value pairs of the environment
variables. The older code looked quite ugly and I tried to revamp it based on
my new knowledge of how performant the different String iteration methods can
be. I wrote a little
[benchmark](../examples/benchmarks/string_ends_with/Sources/main.swift)
to learn more about them.

I learned that using the advancedBy calls was to be faster than first converting
it all to a UInt8 array. The problem with the advancedBy calls is that they are
too verbose. I was having trouble keeping it within 80 columns. Breaking up the
range statements was not easy either. That's why I had the idea to try to extend
the UTF16 view of the String, and it worked! I added these methods that I found
very handy:

```swift
public extension String.UTF16View {

  // Handy method for obtaining a string out of UTF16 indices.
  public func substring(startIndex: Int, endIndex: Int)
      -> String? {
    return String(self[self.startIndex.advancedBy(
        startIndex)..<self.startIndex.advancedBy(endIndex)])
  }

  // Handy method for obtaining a UTF16 code unit to compare with.
  public func codeUnitAt(index: Int) -> UInt16 {
    return self[startIndex.advancedBy(index)]
  }

}
```

They can be accessed from "some string".utf16.codeUnitAt(3). Like that. With
those methods we can try to banish the advancedBy indices to the core extensions
instead and help Swift to keep its cleanliness.

Dart is another language that provides these codeUnitAt and substring methods.
That's where I got the idea for it. While I have not yet added these extensions
to the UTF8 view as well, the possibility is there.

Swift stores its String data into UTF16 byte arrays, and only converts it to
other formats when we need it to. That is to say that when operating on Swift
strings, the UTF16 methods could be slightly faster at least.

Iterating over strings only a couple of times is more performant when using the
advancedBy method. Say you want to check whether the string has a new line at
its end. That's the kind of checking that does not need a full conversion to an
array first at all. But then the advancedBy methods are way too verbose to be
used by end-users on a daily basis.

I'd advocate for the codeUnitAt and substring methods to be added to the core
of Swift for everyone. But I don't know what methods people have in their Core
Foundation support coming from the Objective-C bindings.
