Swift Delta Blue
----------------

The Delta Blue benchmark is used to test the performance of Object Oriented
code. It was first created for Smalltalk, and has since been ported to several
other languages.

In trying to learn more of Swift I decided to port the benchmark to Swift. I
also wanted to compare the performance of different languages.

Dart is a programming language that excels at this Delta Blue benchmark, as the
benchmark was used as one of the official benchmarks when developing the Dart
language implementations.

Swift is a programming language that offers a ton of Object Oriented programming
support. That's one of the things that I like about Swift, even though Swift
also comes with some non-OO features.

Sample Results
--------------

Given that this is a benchmark, let's see some results of running the code:

```
$ time .build/release/swift_delta_blue
14065400

real	0m0.122s
user	0m0.120s
sys	0m0.000s

$ /home/dewd/apps/dart-sdk/bin/dart delta_blue.dart
14065400
elapsed: 0.062
```

Challenges when porting it
--------------------------

Swift tries to enforce non-null values by default. I was porting the code from
more dynamic languages like Wren and Dart. I opted for porting the Wren code to
Swift because it used less types, and Swift does a lot of type inference which
is a good match. I also read code without so many types a little better, as I
am not so used to types all the time at all.

When porting it, the Swift compiler was complaining all the time, producing
many errors and warnings. It was hard to keep the compiler happy while adjusting
the code to fit Swift. Most of the tough choices I had to make were about
comparisons and null values. And that's where I made some mistakes in the port.

One of the big mistakes I made was to define custom "func ==()" comparisons for
the Strength and Constraint classes. In other languages we compare object
identity a lot more, which was the case in the Delta Blue benchmark. All of a
sudden I was trying to compare objects based on their values instead. When I
found out about Swift's "===" and "!==" identity comparisons, I removed the
custom comparison code and that fixed some issues.

I was doubting my usage of code to wrap or unwrap Optional types. That was also
something new to me. And the last major mistake I had lurking in the port was
exactly in one of those "to silence the compiler" instances. Namely, I had a
"if let determining = v.determinedBy {" blocks that was causing necessary code
inside it not to run, probably because "determining" was resulting in null.
Funny thing though was that I think I could finally remove the "if let" code
because of a previous change to use more identity comparisons with "==="
instead. I think it's because identity comparisons can check for null values
without the need for more wrap/unwrap/what-have-you. :-P

More Delta Blue
---------------

You can find other versions of the Delta Blue benchmark in these repositories:

* https://github.com/munificent/wren/tree/master/test/benchmark
* https://github.com/xxgreg/deltablue
