

public extension String {

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
