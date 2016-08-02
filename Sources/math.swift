

public class Math {

  public static func abs(_ n: Int32) -> Int32 {
    return Sys.abs(n: n)
  }

  public static func abs(_ n: Int) -> Int {
    return Sys.abs(n: n)
  }

  public static func round(_ f: Double) -> Int {
    return Sys.round(f: f)
  }

}
