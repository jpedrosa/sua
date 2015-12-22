
Word Counter Example
--------------------

Woot! My first actually working [example](Sources/main.swift) in Swift. Linux
has the "wc" command that counts new lines, bytes and words. I was inspired to
come up with my own version of it as a way to exercise this library that I've
been creating.

For Sua I recently added support for reading from Standard Input and also
a helper class (or struct) for parsing bytes which I used in Dart quite a bit,
called CodeUniStream.

Based on those advancements, I was able to create this Word Example in very few
lines, since most of the code is now found in pretty reusable libraries.

Let's see an example run here:

```
$ .build/release/WordCounter < Sources/main.swift
  38   151   952
$ wc < Sources/main.swift
 38 151 952
 ```

They match! Woohoo! :-)

"wc" actually has other features that are inspiring to continue to work on the
Sua library. One of them is a glob feature that expands the searching to many
files. Here's a sample run:

```
$ wc ../../Sources/*
 2022  7145 46064 ../../Sources/codeunitstream.swift
    9    14    83 ../../Sources/dir.swift
   75   255  1882 ../../Sources/file_browser.swift
  198   654  4550 ../../Sources/file.swift
   83   322  2152 ../../Sources/io.swift
   18    51   301 ../../Sources/lang.swift
   47    73   681 ../../Sources/main.swift
  227   879  5899 ../../Sources/murmurhash3.swift
   46   142  1095 ../../Sources/popen_stream.swift
   88   318  2036 ../../Sources/rng.swift
  127   461  3133 ../../Sources/stat.swift
  117   373  2754 ../../Sources/stdin.swift
   16    42   299 ../../Sources/stdout.swift
   68   281  1824 ../../Sources/string.swift
  251   877  6017 ../../Sources/sys.swift
   64   142  1035 ../../Sources/tick.swift
 3456 12029 79805 total
 ```

 But I don't have support for that yet. I do have code in Dart that handles
 searching of files with glob matching. So that is a possibility in the future.
