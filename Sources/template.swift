

public class Template {

  // Replaces a given token with data passed by the dictionary.
  // E.g.
  //     let template = "ab cd [S%= list S] ef [S%=goodiesS]gh"
  //     print(Template.supplant(template,
  //         data: ["list": "more gain!", "goodies": "fruits"]))
  //     // Which prints the following:
  //     //> ab cd more gain! ef fruitsgh
  public static func supplant(template: String, data: [String: String])
      -> String {
    let a = Array(template.utf16)
    let len = a.count
    var i = 0
    var s = ""
    let vlen = len - 7
    let clen = len - 2
    func collect(startIndex: Int, endIndex: Int) -> String? {
      return template.utf16.substring(startIndex, endIndex: endIndex)
    }
    var si = 0
    while i < vlen {
      // [ 91, S 83, % 37, = 61
      if a[i] == 91 && a[i + 1] == 83 && a[i + 2] == 37 && a[i + 3] == 61 {
        let blockStart = i
        i += 4
        while i < clen && a[i] == 32 {
          i += 1
        }
        var c = a[i]
        if (c >= 97 && c <= 122) || (c >= 65 && c <= 90) || c == 95 {
          let tokenIndex = i
          repeat {
            i += 1
            c = a[i]
          } while i < clen && ((c >= 97 && c <= 122) || // a-z
              (c >= 65 && c <= 90) || (c >= 48 && c <= 57) || // A-Z 0-9
              c == 95) && // _
              !(c == 83 && a[i + 1] == 93) // S]
          let ei = i
          while i < clen && a[i] == 32 {
            i += 1
          }
          if i < clen + 1 && a[i] == 83 && a[i + 1] == 93 { // S ]
            if let k = collect(tokenIndex, endIndex: ei) {
              if let v = data[k] {
                if let bs = collect(si, endIndex: blockStart) {
                  s += bs
                }
                s += v
                si = i + 2
              }
            }
          }
        } else {
          i -= 1
        }
      }
      i += 1
    }
    if let ms = collect(si, endIndex: len) {
      s += ms
    }
    return s
  }

}
