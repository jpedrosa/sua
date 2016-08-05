
public class Stdout {

  public static func write(_ s: String) {
    print(s, terminator: "")
    IO.flush()
  }

  public static func write(bytes: [UInt8], max: Int) -> Int {
    var r = bytes
    let n = Sys.write(fd: PosixSys.STDOUT_FD, address: &r, length: max)
    IO.flush()
    return n
  }

}
