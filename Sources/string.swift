

public extension String {

    /**
        fromCharCodes can take an array of char codes from which a new
        String will be generated.
        The start and end parameters can be omitted.
        The end parameter is inclusive. If the end parameter is negative,
        the end will be interpreted to be the value of the count of the array.
        **Note**: if the range includes a null value (0), since the String
        will be generated using a null-delimited C String function, the
        String may be truncated at the null value instead.
        Ex:
            var a: [CChar] = [72, 101, 108, 108, 111]
            print(String.fromCharCodes(a)) // Prints Hello
            print(String.fromCharCodes(a, start: 1, end: 3)) // Prints ell
    */
    static func fromCharCodes(charCodes: [CChar], start: Int = 0,
        end: Int = -1) -> String {
      let len = charCodes.count
      let lasti = len - 1
      let ei = end < 0 ? lasti : end
      if (ei < start) {
        return String()
      } else {
        if ei < lasti {
          let zi = ei + 1
          var a = [CChar](charCodes[start...zi])
          a[a.count - 1] = 0
          return String.fromCString(&a)!
        } else {
          var a = [CChar](charCodes[start...lasti])
          a.append(0)
          return String.fromCString(&a)!
        }
      }
    }

}
