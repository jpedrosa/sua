Momentum
--------

[Momentum](../Sources/momentum.swift) is a web server that enjoys an API
resembling the servlet APIs from Java, but Momentum also enjoys a registering
API similar to Ruby's Sinatra.

A very simple server can be started with just a couple of lines of code:

```swift
try Momentum.listen(8777) { req, res in
  res.write("<p>Hello Reddit!</p>\(req)")
}
```

And upon a request, it would print the following on the browser:

    Hello Reddit!

    Request(method: "GET", uri: "/", httpVersion: "HTTP/1.1", fields: ["Accept-Encoding": "gzip, deflate, sdch", "Upgrade-Insecure-Requests": "1", "Connection": "keep-alive", "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", "Host": "127.0.0.1:8777", "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/47.0.2526.73 Chrome/47.0.2526.73 Safari/537.36", "Accept-Language": "en-US,en;q=0.8,pt-BR;q=0.6,pt;q=0.4", "Cookie": "session_id=f71f590fe6b8cf6080041aabf0b92ddfcfafc914; GUID=ACa1rS28CrGveCvBAKXx; sessions=%7B%7D"], body: nil)

To make Momentum possible I also worked on several supporting classes. Some of
this work originated in my experiments in another project for the Dart runtime
called Fletch, such as the Momentum basic APIs and the
[HeaderParser](../Sources/header_parser.swift) class.

In the past few days I also worked on classes like the
[BodyParser](../Sources/body_parser.swift),
[Template.supplant](../Sources/template.swift) method, and even on a
[CSVTable](../Sources/csv_table.swift)
that is a table for comma-separated values that helps with prototyping, which
I used for the traditional TodoList example that follows here:

```swift
import Glibc
import CSua
import Sua


func loadTable() throws -> CSVTable {
  let tablePath = "/tmp/todo_sample_table.csvt"
  if File.exists(tablePath) {
    return try CSVTable(path: tablePath)
  } else {
    var table = try CSVTable.create(tablePath, header: ["Done", "Description"])
    try table.append(["n", "New year resolution."])
    try table.save()
    return table
  }
}

var webDirectoryPath = ""

Momentum.get("/hey") { req, res in
  res.write("Hey there!")
}

Momentum.get("/list") { req, res in
  let template = try IO.read("\(webDirectoryPath)list.html") ?? ""
  let data = try loadTable()
  var s = ""
  for row in data.rows {
    let y = row[1] == "y"
    s += "<p class=\""
    s += y ? "donePanel" : "notDonePanel"
    s += "\"><button class=\""
    s += y ? "doneButton" : "notDoneButton"
    s += "\" onclick=\"toggleDone(\(row[0]))\">"
    s += y ? "Done!" : "Not Done!"
    s += "</button> &nbsp; <button class=\"deleteButton\" "
    s += "onclick=\"deleteTodo(\(row[0]))\">X"
    s += "</button> &nbsp; <span class=\""
    s += y ? "doneDescription" : "notDoneDescription"
    s += "\">\(row[2])</span></p>"
  }
  res.write(Template.supplant(template, data: ["list": s]))
}

Momentum.post("/add") { req, res in
  var data = try loadTable()
  if let b = req.body,
      let desc = b.fields["description"] {
    try data.append(["n", desc])
    try data.save()
  }
  res.redirectTo("/list")
}

Momentum.post("/update") { req, res in
  var data = try loadTable()
  if let b = req.body,
      let tgIndex = b.fields["toggleDone"],
      let row = data.select(tgIndex) {
    data.updateColumn(row[0], columnIndex: 1, value: row[1] == "y" ? "n" : "y")
    try data.save()
  }
  res.redirectTo("/list")
}

Momentum.post("/delete") { req, res in
  var data = try loadTable()
  if let b = req.body,
      let index = b.fields["index"] {
    data.delete(index)
    try data.save()
  }
  res.redirectTo("/list")
}

// Serve the image dynamically.
Momentum.get("/bg.png") { req, res in
  let imgPath = "\(webDirectoryPath)bg.png"
  if File.exists(imgPath) {
    res.contentType = "image/png"
    try res.sendFile(imgPath)
  } else {
    res.statusCode = 404
    res.write("<p>Error 404: Could not find the image.</p>")
  }
}

Momentum.post("/setbg") { req, res in
  if let b = req.body,
      let bf = b.files["picture"] {
    try bf.rename("\(webDirectoryPath)bg.png")
  }
  res.redirectTo("/list")
}


func printUsage() {
  print("TodoList: TodoList pathToWebDirectory\n" +
      "Usage: Start the TodoList server by passing it the path to the web " +
      "directory.\n" +
      "E.g. > TodoList web\n")
}


if Process.arguments.count == 1 {
  printUsage()
} else {
  let d = Process.arguments[1]
  if let st = File.stat(d) {
    if st.isDirectory {
      let cd = Dir.cwd ?? ""
      if d.utf16.codeUnitAt(d.utf16.count - 1) != 47 { // /
        webDirectoryPath = "\(cd)/\(d)/"
      } else {
        webDirectoryPath = "\(cd)/\(d)"
      }
      let port: UInt16 = 8777
      print("Starting the server on 127.0.0.1:\(8777)")
      print("Serving from the \(webDirectoryPath) directory.")
      try Momentum.listen(port) { req, res in
        res.statusCode = 404
        res.write("<p>Error 404: Could not find the page.</p>\(req)")
      }
    }
  } else {
    print("Error: Invalid directory path.\n")
    printUsage()
  }
}
```

In the end, creating the TodoList example really pushed me to come up with all
the tools that would allow it to be possible.

The BodyParser class can parse form content and files, and will return them via
the Request#body method. Fields can be accessed via
Request#body#fields[fieldName] and files can be accessed via
Request#body#files[fieldName]. The BodyParser is fully streamed so it could
potentially handle very big files, but the algorithm is a custom one that I
created myself and it may be a little inefficient at times. Considering though
that transfering files via the network is kind of slow, it should not be too CPU
bound at all. :-)

The TodoList example actually includes a form field that accepts a file upload
for setting its background image. As a way to exercise the APIs.

Another gain for us was the Template.supplant method. It can insert some data
strings into a template with code like this:

```swift
let template = "ab cd [S%= list S] ef [S%=goodiesS]gh"
print(Template.supplant(template,
    data: ["list": "more gain!", "goodies": "fruits"]))
// Which prints the following:
//> ab cd more gain! ef fruitsgh
```

I figure that this templating mechanism is pretty OK since Momentum is a forking
process server by default which means that caching templates is not a good
idea. Then again, I ran a quick benchmark round with Apache's "ab" and we are
still quick:

```
$ ab -n 1000 -c 10 http://127.0.0.1:8777/list
[...]
Document Path:          /list
Document Length:        3422 bytes

Concurrency Level:      10
Time taken for tests:   0.258 seconds
Complete requests:      1000
Failed requests:        0
Total transferred:      3500000 bytes
HTML transferred:       3422000 bytes
Requests per second:    3881.82 [#/sec] (mean)
Time per request:       2.576 [ms] (mean)
Time per request:       0.258 [ms] (mean, across all concurrent requests)
Transfer rate:          13267.95 [Kbytes/sec] received
[...]

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.1      0       2
Processing:     0    2   2.0      2      11
Waiting:        0    2   2.0      2      11
Total:          0    3   2.0      2      11

Percentage of the requests served within a certain time (ms)
  50%      2
  66%      3
  75%      3
  80%      4
  90%      6
  95%      7
  98%      8
  99%      9
 100%     11 (longest request)
```

Some of the APIs could be used on their own separate from the Sua project. Be
sure to borrow them for your own needs! :-)
