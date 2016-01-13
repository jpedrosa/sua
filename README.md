Sua
---

![Sua Logo](docs/images/sua_logo.png)

Sua provides Swift users with a new set of core libraries that mostly depend on
Glibc. The work on this project started on Ubuntu/Linux, but it could also be
made to work on OSX by depending on Darwin there.

The idea for this project started as an experiment to see how viable using Swift
under Linux would be. And the results have shown that it is plenty viable. This
project has quickly garnered many important classes that help with dealing with
files, directories, time, some parsing, some more IO, and on we go!

By starting anew, we get to pick some new API names that are shorter and
sweeter.

----------

**News - January 13, 2016**

Great news! With the [Momentum](docs/Momentum.md) web server, and a handful of
supporting classes like [HeaderParser](Sources/header_parser.swift),
[BodyParser](Sources/body_parser.swift),
[Template.supplant](Sources/template.swift), we have found a use for many APIs.
It helped to put to use some of the earlier APIs, with many of them being
refactored as they started to mature.

----------

**News - December 30, 2015**

We have added the [LICENSE.txt](LICENSE.txt) file and took the opportunity to
rename the project to just Sua from Sua Swift. The reason for the change is
to avoid using the trademarkable name Swift in the name of the project itself.
It may help us to comply with the Swift license itself too.

----------

**News - December 29, 2015**

I am so happy that we now have a [Time](Sources/time.swift) class as well. It
took quite a bit of work to get it off the ground. But the results have been
pretty good so far. The Time class is like our own version of the DateTime class
in other languages. And it has a shorter name to boot! And lots of
[shortcut features](docs/Time.md)!

----------

**News - December 25, 2015**

While this project is still in an experimental phase, it has started to become
more useful with classes like [FileBrowser](Sources/file_browser.swift),
[RNG](Sources/rng.swift), [File](Sources/file.swift),
[ByteStream](Sources/byte_stream.swift), [Stopwatch](Sources/tick.swift),
etc.

We still miss a class for dealing with DateTime. And that's a big miss. But I
consider this project to be worth of a version number like 0.1 at least. In my
own repository I have a tag for it of 0.3.3 which coming from 0.0.1 seems like
a lot of ground covered.

----------

Swift has recently been released as open source and is supported on Ubuntu. But
it seems as though that the main APIs are still too heavily dependent on OSX,
even if there are signs that they may be reimplementing many of the APIs on
Swift itself and they may be more portable then.

While Swift may come with standard libraries, the fact that Swift has great
support for calling C libraries directly means that it is easy to experiment
with new libraries and APIs for Swift. The combination of Swift + Linux will
be explored for many years to come and it may give rise to many such libraries,
until a major project based on them takes over the scene.

With Sua Swift, I start on that path for leaner APIs for Swift. The examples
that I come up with may help to document Swift further, if anything.

Sua is a Portuguese word that means "yours". Sua Swift means "your Swift". It
also is a play on how both words are pronounced, both beginning with about the
same sound. Sua also resembles another programming word in Portuguese that is
well known, "Lua" of the Lua programming language fame.

Given how short the Sua word is, it could also be used as a prefix in some words
to help to avoid name conflicts with more standard APIs.

License
-------

See the [LICENSE.txt](LICENSE.txt) file.

Progress Notes
--------------
*LATEST*

* [Momentum](docs/Momentum.md)
* [ServerSocket](docs/ServerSocket.md)
* [Time](docs/Time.md)
* [File Browser](docs/File_Browser.md)
* [String Extensions](docs/String_Extensions.md)
* [Data Types](docs/Data_Types.md)
* [December 11, 2015](docs/Progress_Notes_December_11_2015.md)

Contributors
------------

* Joao Pedrosa - joaopedrosa at gmail.com
