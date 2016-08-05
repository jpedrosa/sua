
import Glibc
import Sua
import CSua


p(MurmurHash3.hash32(key: "kinkajou"))

var a: [CChar] = [107, 105, 110, 107, 97, 106, 111, 117]

p(MurmurHash3.hash32CChar(key: a, maxBytes: a.count))

var b: [CChar] = [112, 97, 110, 100, 97]

p(MurmurHash3.hash32CChar(key: b, maxBytes: b.count, seed: 10))

var c: [UInt8] = [112, 97, 110, 100, 97]

p(MurmurHash3.hash32Bytes(key: c, maxBytes: c.count, seed: 10))

p(MurmurHash3.hash32(key: "panda", seed: 10))

p("-------")

p(MurmurHash3.hash128(key: "kinkajou"))

p(MurmurHash3.hash128CChar(key: a, maxBytes: a.count))

p(MurmurHash3.hash128CChar(key: b, maxBytes: b.count, seed: 10))

p(MurmurHash3.hash128Bytes(key: c, maxBytes: c.count, seed: 10))

p(MurmurHash3.hash128(key: "panda", seed: 10))
