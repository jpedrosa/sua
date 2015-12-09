
public class Stdout {

  public static func write(s: String) {
    print(s, terminator: "")
    IO.flush()
  }

}
