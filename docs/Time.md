Time
----

Such a short word and yet so full of dimensions to it.
[Time](../Sources/time.swift) is a scary feature
to add support for. But it's also a really cool feature that is very much
useful.

Now we can even format it using some C-like features:

```swift
print(Time().strftime("%Y-%m-%d %H:%M:%S"))    // Prints: 2015-12-29 05:47:13
```

With Swift we don't have easy access to variadic C functions like strftime. So
this is a custom function that is not very thorough at the moment. I first came up
with versions of it in JavaScript and Dart. It was originally based on a version
of it created by a famous Ruby developer called _why.

Now that we have the tools, we can even try to find the files that have been
modified recently:

```swift
var t = Time()
t.hour -= 6
//t.minute -= 30
var searchTime = t.secondsSinceEpoch
FileBrowser.recurseDir("../../") { name, type, path in
  if type == .F {
    if let sb = File.stat("\(path)\(name)") {
      if sb.atime.tv_sec >= searchTime {
        print("\(path)\(name): \(sb.atimeAsTime)")
      }
    }
  }
}
```

That would locate the files in the given directories that have been accessed in
the last 6 hours. The Time class allows for arithmetic on its second, minute,
hour and day properties.

As the documentation on the Time class shows, we have features like these now:

```swift
var t = Time()           // Creates a new Time object set on local time.
var u = Time.utc()       // Creates a new Time object set on UTC time.
print(Time().strftime("%Y-%m-%d %H:%M:%S")) //> 2015-12-29 05:28:20
print(Time() == Time())  // Prints true
print(Time().secondsSinceEpoch) // Prints 1451377821
var k = Time(year: 2016, month: 12, day: 30) // Creates a new Time object.
// As does this:
Time.utc(year: 2016, month: 12, day: 30, hour: 5, minute: 3, second: 1)
var r = Time()
r.minute -= 30           // Goes back in time half an hour.
r.day += 7               // Goes forward a week.
```

To support the Time class I had to add other classes like the TimeBuffer that
holds a C "tm" struct buffer. This is then passed to C functions such as the
localtime_r and gmtime_r to fill the buffer with data. The TimeBuffer is very
bare-bones. The higher level features are found in the Time class instead.

Another class that was added was the [Locale](../Sources/locale.swift) class.
The Locale class also holds some relevant data such as the names of months and
weekdays as used by the strftime function. The Locale class could be expanded
into subclasses that dealt with locale-specific translations. I also had a
similar Locale class in Dart and even before in JavaScript.

I don't really know whether I got enough of the details right. I had to decide
on things such as whether the months would be zero-based like in C and
JavaScript, or whether they would start at 1 which is what happens in Dart
and Ruby. I really did not like the zero-based one, because it made the literal
data very error-prone. It even got me once when I was creating the countYeardays
method. So I'm happy that I chose it to go from 1 to 12 like we all prefer. :-)

Another choice I had to make was whether the default time would be taken in UTC
or local time. I preferred local time and I checked it on Dart and they have it
as local time by default as well.

A small feature that I like is the arithmetic on day, hour, minutes and seconds
as added to the Time class itself. It helps that the Time class is actually a
struct. Structs in Swift have the property of Copy-on-Write which makes them a
little safer to share around even as they are modified. When a struct is
modified, only its version pointed at by the current variable is modified. The
other versions based on it, whether they came before or after, don't see the
changes.

Unlike in Dart which has custom methods for comparing DateTime like isAfter, in
the Time class we can do comparisons with just the ordinary comparison
operators, which I prefer a lot more. Even though it might not always make sense
to compare Times without taking into serious consideration issues such as
TimeZone, sometimes it is as though it just works as both UTC and local time
may have the same secondsSinceEpoch amount so they seem to be comparable as
well. At least based on some of the tests that I did.

```swift
var t = Time()
var t2 = t
t.minute += 1
print(t == t2)  // Prints false
t2.minute += 1
print(t == t2)  // Prints true
```

That's it for now. Happy new year!

```swift
var d = Time.utc(year: 2015, month: 12, day: 31, hour: 23, minute: 59,
    second: 59)
print(d.strftime("%Y-%m-%d %H:%M:%S"))    // Prints: 2015-12-31 23:59:59
d.second += 1
print(d.strftime("%Y-%m-%d %H:%M:%S"))    // Prints: 2016-01-01 00:00:00
```

P.S. I am finishing writing this code as I'm writing this post. In fact I just
fixed an issue caused by one of my recent changes to make the Time class be
local time by default. I will commit the fix together with this article if you
want to see it. And above all, you're welcome to help me to fix any other issues
or to make the Time class even better! Cheers!
