
public class Stdout {

  public static func write(s: String) {
    print(s, terminator: "")
    IO.flush()
  }

  public static func writeBytes(a: [UInt8], maxBytes: Int) -> Int {
    var r = a
    let n = Sys.write(PosixSys.STDOUT_FD, address: &r, length: maxBytes)
    IO.flush()
    return n
  }

}
