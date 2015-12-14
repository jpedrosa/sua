Swift, What Comes To Mind
-------------------------

I've been wanting to write about the
[Swift](https://github.com/apple/swift)
programming language a lot more.
First, because I am impressed by what they have created in Swift. Second,
because it seems that the world is still largely unaware of what Swift provides.

Still, there is a nagging feeling in the back of my mind
[humming](https://www.youtube.com/watch?v=FRR9ud__QtI) "Shut Up and
Code!" Not that there is any music about that that I know of. :-)

Hello, world!
-------------

My first "Hello, World!" in Swift was like this. First with the REPL:

```
$ swift
Welcome to Swift version 2.2-dev (LLVM 7bae82deaa, Clang 53d04af5ce, Swift 5995ef2acd). Type :help for assistance.
  1> "Hello, World!"
$R0: String = "Hello, World!"
  2> 2 + 3
$R1: Int = 5
  3>
```

REPL stands for Read, Eval, Print Loop. It can run code as we type it in,
allowing for short experimentation and even some longer coding sessions that
people then save in a file later on. One of the first languages providing for
REPL that many of us used was Ruby. Ruby has the "irb" command that starts a
session like that of Swift above. The fact that Swift also has it serves as a
hint to how Swift's features came together.

My second "Hello, World!" with Swift was remarkably based on a surprise. I
created a file that I expected to compile with Swift. But since I was learning
Swift on my own at the same time, I didn't really know what to call exactly.
So I created a file like this:

```
$ echo 'print("Hello, World!")' > hello_world.swift
$ cat hello_world.swift
print("Hello, World!")
$ swift hello_world.swift
Hello, World!
$
```

As you can see, once I called the file with the "swift" command, it ran the file
right away. Wait a minute! One would wonder. Wasn't it supposed to compile it
first? It ran the file like it was an interpreter. I was left speechless and
laughing out loud for many minutes, I'm afraid to admit.

Long story short, I learned about the limitations of Swift's interpreter once
I started trying to translate
[code](../examples/benchmarks/swift_delta_blue/Sources/delta_blue.swift)
from some other languages into Swift. Namely, the Swift interpreter cannot
resolve the names of things like methods, classes, etc in a broad way because
it resolves them as it reads the file instructions, so first come, first serve,
and with interdependencies where A depends on B and B depends on A it is
difficult for the interpreter to deal with at this point. Such limitations could
be reduced in the future, but the interpreter is not at this time Swift's main
feature. That would be the compiler and how the third "Hello, World!" example
could have been created instead:

```
$ mkdir HelloWorld
$ cd HelloWorld/
$ echo 'print("Hello, World!")' > main.swift
$ touch Package.swift
$ swift build
Compiling Swift Module 'HelloWorld' (1 sources)
Linking Executable:  .build/debug/HelloWorld
$ .build/debug/HelloWorld
Hello, World!
$
```

Notice that we have created examples in 3 different Swift modes: REPL,
interpreter and compiler. And we did not even need to use an IDE to do them
with. In fact, I ran these examples on Ubuntu Linux which is part of [Swift's
open sourcing](https://swift.org/) venture.

Swift is Open Source
--------------------

Since early December of 2015, Swift has been made Open Source. It means at a
basic level that current users of Swift can
[browse Swift's code](https://github.com/apple/swift/tree/8d9ef80304d7b36e13619ea50e6e76f3ec9221ba/stdlib/public/core)
on GitHub to see what is in the source code to better understand the features
and limitations present in Swift and perhaps to help to improve Swift by
reporting bugs, help with sending custom fixes of their own, and even to better
write about the inner-workings of Swift.

Swift being open source is impressive. First, it shows Apple's commitment to
the platform. In watching one of Apple's conference videos, one of the Apple
representatives mentioned that Swift could be a useful programming language for
the next 20 years.

Developing programming languages is difficult. Your choices, your bugs in
developing the features of the programming language, could result in many issues
for the ordinary developers using them and for their own users. And at times
there seems to be no end to it as you have to keep adapting the implementations
to the future needs and platforms. Just Apple seem to have about 4 or so
different platforms of their own. Swift has to work for all of them, while
taking into consideration past and future needs.

While developing a programming language, you could have to choose between
providing the power users with features that they could hurt themselves with and
try to keep the end-users in a safer bubble so that they would help with not
allowing hackers and whatnot from taking advantage of their systems. Often a
lot is sacrificed in trying to create the safety bubble that will help to
sanitize and sandbox code that cannot be fully trusted. Swift comes with many
safety features, but they are easy to work around, so that Swift is not a
language to be sandboxed like JavaScript is. In the future, they may hope to
further develop the interpreter so that it could be better sandboxed and they
would retain most other Swift features. But that is the kind of holy grail that
we have yet to see anyone conquer. Sandboxed languages can be slow and boring
for some needs that better take advantage of the platforms.

Kids, pick the ingredients the chef will use to cook you dinner
---------------------------------------------------------------

That's how diverse the ingredients that have been used to create Swift have
been. In a language designed by committee, the ingredients are chosen more
for conformance than for stirring the pot. Swift was not created by a committee
per se. Although I'm sure that many of its core developers helped to give it
ideas and features.

The kids chose these ingredients for Swift: Objective-C, C++, C, LLVM, Ruby,
JavaScript, Python, Haskell, Rust, Go, REPL, interpreter, compiler, package
manager, immutable, non-null by default, exceptions, Unicode, OOP, functional,
closures, native, conciseness, pattern matching, Scala, Java, Apple Script,
descriptive names, Smalltalk, named parameters, default parameter names, enum,
struct, class, debugger, tuples, reference counting, type inference and in the
future ABI compatibility...

Now make me a language based on features from all of those and more. And they
did. It's called Swift.

They had to interop with Objective-C because many of Apple's platforms have
depended on Objective-C. The fact that they were pushed by this requirement
ended up making Swift one of the best for interoperating with languages like C
and Objective-C. All while trying to be safe about it so that users don't mess
up with their computer's memory by mistake.

From Ruby they also got some higher level features. Recall that Apple once
supported a Ruby version called MacRuby. It was Ruby with named parameters and
stuff. It shows that Apple had a knack for Ruby. When we write code like this
in Swift:

```
$ cat knack.swift
let scores = [3, 9, 1, 0, 5, 8]
let doubleScoresSorted = scores.map{ $0 * 2 }.sort()
print(doubleScoresSorted)
$ swift knack.swift
[0, 2, 6, 10, 16, 18]
$
```

It shows an extreme resemblance to a Ruby version of it, does it not?

```
$ cat knack.rb
scores = [3, 9, 1, 0, 5, 8]
doubleScoresSorted = scores.map{|n| n * 2 }.sort
p doubleScoresSorted
$ ruby knack.rb
[0, 2, 6, 10, 16, 18]
$
```

When I first learned Ruby many years ago, one of the first things I noticed
about Ruby was how close to C it was. Not in source-code compatibility. But in
being able to use C and to call into C. Many of Ruby's features were written in
C. Ruby was not as fast as C, so it took advantage of calling into C a lot. It
had an intricate relationship with C. Swift also has an intricate relationship
with C, with Objective-C and perhaps even with C++ which is used to develop its
compiler with.

C++ is a fast language with some higher level features. It is verbose, but for
writing multi-year projects that never seem to end like compilers and
interpreters for popular languages like JavaScript, C++ is a must. It helps to
give the languages it empowers a lot of performance and fast loading features.
The fact that Swift's own compiler uses C++ gives Swift some of those
advantages. Being able to compile tens of thousands of lines of code, if not
millions, in a timely manner is necessary. Languages like Swift that have
complicated type systems can slow down the compilation process a lot, so being
able to get past that process as quickly as possible is a must.

Type Inference
--------------

Swift enjoys Type Inference. Types can be surmised from a previous declaration
so that you don't need to repeat them all the time. In my experience it has
worked well so far. It may require that source-code always be present when
compiling modules and their dependencies to give the information that the
compiler needs to match the types and so on. But since source-code is ever more
present, it's generally OK. It is a trade-off that must be accounted for when
compared to languages like JavaScript whose dynamically loading system
disregards types almost entirely until the last minute when they are compiled in
the end-users' computers.

Type Inference is one of those features that come more from the functional
language side of the spectrum. Together with Type Inference, the use of
Optionals to wrap values that can be null, easily obtained closures, pattern
matching and probably more features also come from this functional language
heritage.

Swift has overloading of methods based on the types of the parameters and even
based on the types of the return values of the functions. While that is a
powerful feature, sometimes we may choose not to abuse them and opt for methods with
different names instead, which also helps with the type inferencing.

If 2 methods differ only on the type of their returns, having both the same name
and parameter names and types otherwise, and you want to call one of those
methods in, say, a closure that is often concise, you want to use the type
inferencing so that the code can continue to be concise. But what if the
compiler cannot tell which of the 2 methods you are calling? It cannot infer it
based only on the return types, so now the compiler complains that the type
is ambiguous. So that it can be better to have 2 different named methods if they
are only different on their return types. Likewise, sometimes calling into methods that
differ only in their parameter types could end up being concerning. Just
because we can overload them, it does not mean that we should. Perhaps we should
take a page from more dynamic languages and have different method names for
slightly different purposes and sometimes add to the method name's the type
instead.

That again goes to show that just because the code can be concise, say
have a method named "read" repeated 5 times based on just different parameter
types and return types, that perhaps it would be better to break it up into
different method names and reserve the main "read" one for the most common
use-case instead.

For reference, see this
[quote by Jordan Rose](https://lists.swift.org/pipermail/swift-evolution/Week-of-Mon-20151207/001199.html)
, one of the Swift developers:


> Swift does support overloading on return type, but the downside is you need to always provide context, which makes it harder to break things up into multiple statements. So we generally avoid it unless there's a compelling reason.
>
> -- Jordan Rose

Performance is like Clockwork
-----------------------------

I was testing a Swift [program](../examples/file_and_io/Sources/main.swift)
set with a repeat timer of 0.05 seconds to repeat this function a 1000 times.
This program would deal with files, print some of their content to output, print
some other file related content to output, some strings, overwrite some files
etc. The program itself was of no particular use, except that I have been using
it to develop a Swift [library](../) with.

While testing it, I had the Linux "top" command open in another tab and I used
it to watch the program's process memory and CPU usage, as I watched the
program's output its content on the other window. First, unlike in scripting
languages like Ruby, we get to see the actual binary name of the program on
that "top" command. Which is by itself rather cool. Second, the program
was consuming a fixed amount of memory and the CPU with the help of the timer
was stuck at 30% usage. It was not even breaking a sweat. The memory was not
increasing like it would have in other garbage collected languages. It was quick
and non-challant. And I could even keep playing a game on another browser window
if I wanted to while it was running, as it was not monopolizing the resources.

It is true that modern computers have a lot of resources available to them, and
that some programs like the Chrome browser try their best to use all of the
available resources if they can. More and more programmers also want to use the
multiple CPUs if they can so that the CPUs don't just sit there idle while they
have important job to do. Still, it's also great that Swift can do its job
without monopolizing the resources. It helps Swift to fit into people's phones,
tablets, watches and perhaps into what they call IoT - Internet of Things
devices that tend to have less resources available to them. It may also help to
conserve important resources like battery life. The Swift developers had these
sort of priorities when they designed it.

Swift on the Server
-------------------

They may think that Swift being made open source will also help it on the
server. It is true that it's an important step. But on the server people have
a large variety of languages to choose from. It's on the server the only place
where many languages can enjoy the spotlight -- how ironic. The programs in the
servers being so far away from people's actual body presence.

Some of the requirements people have for languages on the server is that they
should hardly change in incompatible ways. Swift is still changing and sometimes
in incompatible ways. Why? Because Swift is foremost a language for the
client-side. A language to be on people's phones. Rather than tucked away into a
server somewhere.

The one thing the languages that work on the server all have in common is that
they strive for backward compatibility. They say that the Go programming
language has hardly changed since its 1.0 release. Partly because Go was a
language designed to be on the server.

A language on the server can run for eternity. A language on the server can
enjoy gigabytes of memory for their garbage collector and can monopolize all the
resources they have available to them. A language on the server that has JIT
compilation can have plenty of time for the compiler to do its best job. If
a program takes minutes to load on the server, it can be amortized by having
other instances taking part of the load in the interim. Or just waiting out.
Once a server is up it can serve millions of users, further amortizing the need
to wait for it to load up.

Users of Go and Java are fine with their languages being more useful on the
server. First they don't want their servers to crash unexpectedly if they can
help it with. It could lose them data. Second, they want to log all the
meaningful exception data so that they can analyze it when an error occurs.

Swift on the other hand has trade-offs that make it better for the client-side.
Even if a Swift program were to crash on the client-side, it would affect at
most 1 user. By starting up quickly and using less memory, Swift programs can
appeal to end-users a lot more on the client. The iPhone has some limitations
for programs that Swift based ones may find easier to stay within the required
boundaries of memory and CPU consumption.

Swift users are busy
--------------------

Over on https://www.reddit.com/r/swift/ Swift users appear to be busy with their
Cocoa and iOS applications. Swift is helped by having a large market to it so
that even if it was a bad programming language, it would have still been popular
enough.

It helps it when programming languages are pushed by major platform vendors like
Apple and Google. It is a lot of investment to get a programming language going.
Sometimes those companies invest into different areas of expertise. Sometimes
they invest more into sandbox requirements than on more native language ones.

Getting a language like Swift up and running is not for the faint of heart. Most
people could not do it. Most companies would rather adopt one of the existing
languages than to try to break some new ground. Apple for decades stuck with
its Objective-C alternative. And for those of us who tried Objective-C and did
not like it right away, Swift has been more than a blessing.

Where is the love?
------------------

It is hard to love programming languages. I don't think that I love Swift. I
used to say that I loved Ruby. I have since used other languages like the Dart
programming language. Swift to me has been energizing. Being able to create
native programs while using a language with a scripting language feel to it is
remarkable. To me, it's better than Python, Go, etc. I have tried many languages
like them but never really grew fond of them. I need my OOP. I need my dynamic
feel to it. And with Swift, the sometimes annoying compiler is back in town. :-)

In my humble opinion, Apple should feel proud of themselves with Swift. The
opportunity to have a language that can be enjoyed by both end-users and power
users is a holy grail that has not been achieved by many languages. Microsoft
had trouble with the C# and C++ bifurcation. Can Swift go where few others have
been able to?

```
$ cat cheers.swift
var a: [Any] = ["**", 1, 2, 3, "Cheers!", true, false, 4.56]
debugPrint(a)
$ swift cheers.swift
["**", 1, 2, 3, "Cheers!", true, false, 4.56]
$
```

- Joao Pedrosa
