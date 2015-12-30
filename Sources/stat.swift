
import Glibc


// The Stat class presents some higher level features, but it still exposes
// some of the lower level APIs for performance reasons.
public struct Stat: CustomStringConvertible {

  var buffer: CStat

  public init() {
    buffer = Sys.statBuffer()
  }

  public init(buffer: CStat) {
    self.buffer = buffer
  }

  mutating public func stat(path: String) -> Bool {
    return Sys.stat(path, buffer: &buffer) == 0
  }

  mutating public func lstat(path: String) -> Bool {
    return Sys.lstat(path, buffer: &buffer) == 0
  }

  public var dev: UInt { return buffer.st_dev }

  public var ino: UInt { return buffer.st_ino }

  public var rawMode: UInt32 { return buffer.st_mode }

  public var nlink: UInt { return buffer.st_nlink }

  public var uid: UInt32 { return buffer.st_uid }

  public var gid: UInt32 { return buffer.st_gid }

  public var rdev: UInt { return buffer.st_rdev }

  public var size: Int { return buffer.st_size }

  public var blksize: Int { return buffer.st_blksize }

  public var blocks: Int { return buffer.st_blocks }

  func tsToTime(ts: CTimespec) -> Time {
    return Time(secondsSinceEpoch: ts.tv_sec, nanoseconds: ts.tv_nsec)
  }

  public var atime: CTimespec { return buffer.st_atim }

  public var atimeAsTime: Time { return tsToTime(buffer.st_atim) }

  public var mtime: CTimespec { return buffer.st_mtim }

  public var mtimeAsTime: Time { return tsToTime(buffer.st_mtim) }

  public var ctime: CTimespec { return buffer.st_ctim }

  public var ctimeAsTime: Time { return tsToTime(buffer.st_ctim) }

  public var isRegularFile: Bool { return (rawMode & S_IFMT) == S_IFREG }

  public var isDirectory: Bool { return (rawMode & S_IFMT) == S_IFDIR }

  public var isSymlink: Bool { return (rawMode & S_IFMT) == S_IFLNK }

  public var mode: StatMode {
    return StatMode(mode: rawMode)
  }

  public var description: String {
    return "StatBuffer(dev: \(dev), ino: \(ino), rawMode: \(rawMode), " +
        "nlink: \(nlink), uid: \(uid), gid: \(gid), rdev: \(rdev), " +
        "size: \(size), blksize: \(blksize), blocks: \(blocks), " +
        "atime: \(atime), mtime: \(mtime), ctime: \(ctime), " +
        "mode: \(mode))"
  }

}


public struct StatMode: CustomStringConvertible {

  var mode: UInt32

  public init(mode: UInt32 = 0) {
    self.mode = mode
  }

  public var isRegularFile: Bool { return (mode & S_IFMT) == S_IFREG }

  public var isDirectory: Bool { return (mode & S_IFMT) == S_IFDIR }

  public var isSymlink: Bool { return (mode & S_IFMT) == S_IFLNK }

  public var isSocket: Bool { return (mode & S_IFMT) == S_IFSOCK }

  public var isFifo: Bool { return (mode & S_IFMT) == S_IFIFO }

  public var isBlockDevice: Bool { return (mode & S_IFMT) == S_IFBLK }

  public var isCharacterDevice: Bool { return (mode & S_IFMT) == S_IFCHR }

  public var modeTranslated: String {
    switch mode & S_IFMT {
      case S_IFREG: return "Regular File"
      case S_IFDIR: return "Directory"
      case S_IFLNK: return "Symlink"
      case S_IFSOCK: return "Socket"
      case S_IFIFO: return "FIFO/pipe"
      case S_IFBLK: return "Block Device"
      case S_IFCHR: return "Character Device"
      default: return "Unknown"
    }
  }

  public var octal: String {
    var a: [UInt32] = []
    var i = mode
    var s = ""
    while i > 7 {
      a.append(i % 8)
      i = i / 8
    }
    s = String(i)
    var j = a.count - 1
    while j >= 0 {
      s += String(a[j])
      j -= 1
    }
    return s
  }

  public var description: String {
    return "StatMode(modeTranslated: \(inspect(modeTranslated)), " +
        "octal: \(inspect(octal)))"
  }

}
