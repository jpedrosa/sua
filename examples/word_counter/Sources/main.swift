
import Glibc
import Sua

if !Stdin.isTerminal {

  var stream = CodeUnitStream()
  var bytesCount = 0
  var newLineCount = 0

  try Stdin.readByteLines() { line in
    let len = line.count
    bytesCount += len
    if len > 0 && line[len - 1] == 10 {
      newLineCount += 1
    }
    p(line)
    p(String.fromCharCodes(line))
    //stream.codeUnits = line
  }

  print("  \(newLineCount)  ( - )   \(bytesCount)")
} else {
  print("Usage: call it by passing a pipe or standard input.\n" +
    "E.g. WordCounter < some_sample.txt\n" +
    "     ls -l | WordCounter")
}
