
import Glibc


public class StatBuffer: CustomStringConvertible {

  var buffer = Sys.statBuffer()
  var _statMode = StatMode()

  public init() {
    buffer = Sys.statBuffer()
  }

  public func stat(path: String) -> Bool {
    return Sys.doStat(path, buffer: &buffer) == 0
  }

  public func lstat(path: String) -> Bool {
    return Sys.lstat(path, buffer: &buffer) == 0
  }

  public var dev: UInt { return buffer.st_dev }

  public var ino: UInt { return buffer.st_ino }

  public var mode: UInt32 { return buffer.st_mode }

  public var nlink: UInt { return buffer.st_nlink }

  public var uid: UInt32 { return buffer.st_uid }

  public var gid: UInt32 { return buffer.st_gid }

  public var rdev: UInt { return buffer.st_rdev }

  public var size: Int { return buffer.st_size }

  public var blksize: Int { return buffer.st_blksize }

  public var blocks: Int { return buffer.st_blocks }

  public var atime: timespec { return buffer.st_atim }

  public var mtime: timespec { return buffer.st_mtim }

  public var ctime: timespec { return buffer.st_ctim }

  public var isRegularFile: Bool { return (mode & S_IFMT) == S_IFREG }

  public var isDirectory: Bool { return (mode & S_IFMT) == S_IFDIR }

  public var isSymlink: Bool { return (mode & S_IFMT) == S_IFLNK }

  public var statMode: StatMode {
    _statMode.mode = mode
    return _statMode
  }

  public var description: String {
    return "StatBuffer(dev: \(dev), ino: \(ino), mode: \(mode), " +
        "nlink: \(nlink), uid: \(uid), gid: \(gid), rdev: \(rdev), " +
        "size: \(size), blksize: \(blksize), blocks: \(blocks), " +
        "atime: \(atime), mtime: \(mtime), ctime: \(ctime), " +
        "statMode: \(statMode))"
  }

}


public class StatMode: CustomStringConvertible {

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
      j--
    }
    return s
  }

  public var description: String {
    return "StatMode(modeTranslated: \(inspect(modeTranslated)), " +
        "octal: \(inspect(octal)))"
  }

}
