
public class Stdout {

  public static func write(s: String) {
    print(s, terminator: "")
    IO.flush()
  }

  public static func writeBytes(a: [UInt8], length: Int) -> Int {
    var r = a
    let n = Sys.write(0, address: &r, length: length)
    IO.flush()
    return n
  }

}
