
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
    try bf.rename(bgImagePath)
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
      try Momentum.listen(8777) { req, res in
        res.statusCode = 404
        res.write("<p>Error 404: Could not find the page.</p>\(req)")
      }
    }
  } else {
    print("Error: Invalid directory path.\n")
    printUsage()
  }
}
