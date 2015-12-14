
var a: [CChar] = [90, 80, 70, -60, -50, 0]

debugPrint(a)

let ptr = UnsafePointer<UInt8>(a)

let bytes = UnsafeBufferPointer<UInt8>(start:ptr, count:6)

debugPrint("bytes: \(bytes)")

debugPrint("bytes: \(bytes[0]) \(bytes[1]) \(bytes[2]) \(bytes[3])")

let anotherPtr = UnsafePointer<CChar>(a)

let moreBytes = UnsafeBufferPointer<CChar>(start:anotherPtr, count:6)

debugPrint("bytes: \(moreBytes[0]) \(moreBytes[1]) \(moreBytes[2]) \(moreBytes[3])")
