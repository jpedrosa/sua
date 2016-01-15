Environment
-----------

Environment variables allow for passing some dynamic configuration data to
programs. With Swift on Linux, I had to come up with my own interface for them.
And even though it's not actually a lot of code, the fact that it works as
beautifully as it does makes me to want to give a shout-out to the Swift
developers!

Thanks, guys!

Have a look at this code:

```swift
public struct Environment: SequenceType {

  public subscript(name: String) -> String? {
    get { return Sys.getenv(name) }
    set {
      if let v = newValue {
        Sys.setenv(name, value: v)
      } else {
        Sys.unsetenv(name)
      }
    }
  }

  public func generate() -> DictionaryGenerator<String, String> {
    return Sys.environment.generate()
  }

}
```

That creates a kind of a class, actually a struct, but it works almost like a
class. The subscript method makes it so that we can work with the instance as
though it was a dictionary, with code between square brackes: ```env["this"]```,
```env["that"] = "other"```. Now for the catch. Since Swift kind of embraces
nil/null types with the usage of optionals, it seems to be standard that when a
nil value is assigned to the dictionary, it actually removes the key from the
dictionary:

```swift
var e = IO.env
p(e["USER"])           // Prints the user name.
e["USER"] = nil
p(e["USER"])           // Now prints nil. The key is gone, too!
```

That's still not too different from other languages. In Dart, for example, we
can overload some operators and get about the same effect. This kind of code was
one of the first things I wanted to try when I started with Swift, since with
Dart I had grown to like it a lot.

Swift is different from other languages in the way that Swift still embraces the
nil value, only it is wrapped in code that is checked by the compiler. It is
annoying at first. When I was first trying Swift, when I was just trying to
"silence" the compiler, it even helped me to cause related bugs. The thing is,
though, that while other languages are trying to get rid of their nil values,
with Swift it is an OK value that we can use in a semantically, positive way. As
in this dictionary code:

```swift
var h = ["flowers": "red", "violets": "blue"]
p(h)                      // Prints ["violets": "blue", "flowers": "red"]
h["flowers"] = nil
p(h)                      // Prints ["violets": "blue"]
```

I'm sure that many developers love their dictionaries, even if they know it by
other names in other languages. It could be their maps, hashes, etc.

But we are still missing the other line that we haven't talked about,
specifically the one with this code:

```swift
public func generate() -> DictionaryGenerator<String, String> {
```

What this does, in combination with the SequenceType Protocol is that it allows
us to iterate over the items of a dictionary with the "for in" loop. Like this:

```swift
for (name, value) in IO.env {
  print("\(name): \(value)")
}
```

That would print each name/value pair on a different line.

In my Environment struct, the environment variables are actually coming from
functions that call into C. The C functions they call are these: [getenv, setenv,
unsetenv and environ.](../Sources/sys.swift#L258) But the environ one is just a
variable that we have to
handle before we can take the data out of it. The fact though is that those 4
different C functions coalesced into just that small struct and a very
user-friendly API was made possible thanks to all the hard-work from the Swift
developers. Not many languages can enjoy that kind of user-interface. It pays in
that end-users can be more productive and the code can be made more clear, with
less verbosity.

Cheers!
