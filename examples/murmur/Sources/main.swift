
import Glibc
import Sua
import CSua


p(MurmurHash3.hash32("kinkajou"))

var a: [CChar] = [107, 105, 110, 107, 97, 106, 111, 117]

p(MurmurHash3.hash32CChar(a, maxBytes: a.count))

var b: [CChar] = [112, 97, 110, 100, 97]

p(MurmurHash3.hash32CChar(b, maxBytes: b.count, seed: 10))

var c: [UInt8] = [112, 97, 110, 100, 97]

p(MurmurHash3.hash32Bytes(c, maxBytes: c.count, seed: 10))

p(MurmurHash3.hash32("panda", seed: 10))
