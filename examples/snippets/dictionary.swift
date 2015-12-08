

class A {

  var map: [String: String?] = [:]

  subscript(key: String) -> String? {
    get { return map[key] ?? nil }
    set(newValue) { map[key] = newValue }
  }

}

var o = A()

print(o["name"])
o["name"] = "Kris"
print(o["name"])

let re = o["re"]
print(re)
