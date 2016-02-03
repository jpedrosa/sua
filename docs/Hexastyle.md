Hexastyle
---------

[Hexastyle](../Sources/hexastyle.swift) is a new encoding format for both style
and color that can be embedded in ordinary text.

The chosen format is this one:

    %busi#FFFFFFFF,FFFFFFFF=            // Extended, most detailed one.
    %busi#FFFF,FFFF=                    // Detailed by including the alpha code.
    %busi#FFF,FFF=                      // Now without the alpha code.
    %busi#FFF=                          // No background this time.
    %bus#FFF=                           // No italics style for this one.
    %#FFF=                              // Skip style entirely.
    %#=                                 // Not even foreground color now. Reset.

Where the styles can be enabled by being included between % and # characters.

  * b - Bold.

  * u - Underline.

  * s - Strikeout or strikethrough.

  * i - Italic.

The rule is that their letter needs to be in lower case and can only be included
once. More than once and the entire code will be ignored and shown in plain
text.

The rule also says that if the code cannot be understood, the entire code will
be shown in plain text. This way it could help with debugging it or even in case
the code was not actually an Hexastyle code to begin with, but just happened to
have about the same characters.

Following the hash character (#) we have the hexadecimal colors, which are based
on the formats found on the web.

  * The hexadecimal color can have just 3 characters which is enough to encode
12 bit of color. It is a shorthand format that helps with saving bytes and
typing.

E.g.

    %#FFF=               // White. Same as %#FFFFFF=
    %#F00=               // Red. Same as %#FF0000=
    %#913=               // Mixed. Same as %#991133=

So that each character gets doubled in its full value representation.

  * The hexadecimal color can include the alpha channel code -- the 4th
character in the shorthand format. Or even the fourth character set on the full
format representation. While the alpha channel may be ignored when it's
interpreted by some program, it's good to be able to encode it as well. Which I
think is not possible on the web hexadecimal format by default. On the web I
have seen the longer formatting with rgba(0, 0, 0, 0) instead for the alpha
channel.

E.g.

    %#00F7=               // Blue with some transparency. Same as %#0000FF77=

  * The background color can also be set with the comma following the foreground
color. So to be able to set the background color, the foreground color needs to
be set first. This could help with making sure that the colors have a good
contrast between themselves.

E.g.

    %#FFF,00F=            // White text on blue background.
                          // Same as %#FFFFFF,0000FF=

  * Finally, the empty Hexastyle code helps to reset it by removing all of the
styles and colors set beforehand.

E.g.

    %#=                   // This resets the styles and colors; back to default.

Hexastyle codes are only valid up to the next Hexastyle code. So in effect the
next Hexastyle code resets the one before it. It also gives more of a WYSIWYG
feel to it as you can be sure that the latest Hexastyle code is the only set of
styles and colors that are present for the text following it. While this can
make it a bit more work when you do want a previous code to carry through other
codes, given the conciseness with which the Hexastyle code can encode a
multitude of styles and colors, you could just repeat the setting for the next
one until you were done with it.

-----------------

The idea for this encoding format started as I wanted to be able to embed
literal text that included styles and colors into the [SuaSDL](../../sua_sdl/)
project. I wanted it to be concise, but that it was not HTML or some other
format that went beyond just the styles and colors.

I have seen colors being embedded in text starting with the mIRC Script and even
before that in BBS systems. Terminals can also include ANSI color codes. But
nowadays we have 32 bit colors and lots of pixels to fill them with. Being able
to encode all of those colors was one of the goals of this project.

Another goal was that the codes be plain text so that they can be stored,
edited, viewed and sent over the network to other clients. By being plain text
there is always the chance that the format could naturally occur in some text
somewhere and that could cause some confusion -- it should be a small chance
though.

These Hexastyle codes could be used in some chatting program somewhere, say on
Twitch bots or some such.

------------------

The Hexastyle class supports parsing text and straight Hexastyle code already:

```swift
p(try Hexastyle.parseText("hello%b#00F= hexastyle!"))
```

It prints this:

    [("hello", nil), (" hexastyle!", Optional(Sua.Hexastyle(style: 2, color: Optional(Sua.RGBAColor(r: 0, g: 0, b: 255, a: nil)), backgroundColor: nil)))]

It can also parse just the Hexastyle code with a different method:

```swift
let ha = "%u#FF0,000=".bytes
p(try Hexastyle.parseHexastyle(ha, startIndex: 1, maxBytes: ha.count))
```

Which prints this:

    (Optional(Sua.Hexastyle(style: 4, color: Optional(Sua.RGBAColor(r: 255, g: 255, b: 0, a: nil)), backgroundColor: Optional(Sua.RGBAColor(r: 0, g: 0, b: 0, a: nil)))), 10)

------------------

Hexastyle is already being useful on the SuaSDL sister project. Since it is a
core functionality that could be useful beyond just the SuaSDL project, I
decided to bring it over to the main Sua project now.

Cheers!
