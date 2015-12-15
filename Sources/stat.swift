

public class StatBuffer: CustomStringConvertible {

  var buffer = Sys.statBuffer()
  //StatMode _statMode;

  init() {
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

  /*// atime_nsec starts at 36.
  int get atime => _bufferForeign.getInt32(32); // Unix time is signed.

  // mtime_nsec starts at 44.
  int get mtime => _bufferForeign.getInt32(40);

  // ctime_nsec starts at 52.
  int get ctime => _bufferForeign.getInt32(48);

  bool get isRegularFile => (mode & MoreSys.S_IFMT) == MoreSys.S_IFREG;

  bool get isDirectory => (mode & MoreSys.S_IFMT) == MoreSys.S_IFDIR;

  bool get isSymlink => (mode & MoreSys.S_IFMT) == MoreSys.S_IFLNK;

  get statMode {
    if (_statMode == null) {
      _statMode = new StatMode(mode);
    } else {
      _statMode.mode = mode;
    }
    return _statMode;
  }*/

  public var description: String {
    return "StatBuffer(dev: \(dev), ino: \(ino), mode: \(mode), " +
        "nlink: \(nlink), uid: \(uid), gid: \(gid), rdev: \(rdev), " +
        "size: \(size), blksize: \(blksize), blocks: \(blocks), "/* +
        "atime: \(atime), mtime: \(mtime), ctime: \(ctime), " +
        "statMode: \(statMode))"*/
  }

}


/*class StatMode {

  int mode;

  StatMode([int this.mode = 0]);

  bool get isRegularFile => (mode & MoreSys.S_IFMT) == MoreSys.S_IFREG;

  bool get isDirectory => (mode & MoreSys.S_IFMT) == MoreSys.S_IFDIR;

  bool get isSymlink => (mode & MoreSys.S_IFMT) == MoreSys.S_IFLNK;

  bool get isSocket => (mode & MoreSys.S_IFMT) == MoreSys.S_IFSOCK;

  bool get isFifo => (mode & MoreSys.S_IFMT) == MoreSys.S_IFIFO;

  bool get isBlockDevice => (mode & MoreSys.S_IFMT) == MoreSys.S_IFBLK;

  bool get isCharacterDevice => (mode & MoreSys.S_IFMT) == MoreSys.S_IFCHR;

  String get modeTranslated {
    switch (mode & MoreSys.S_IFMT) {
      case MoreSys.S_IFREG: return "Regular File";
      case MoreSys.S_IFDIR: return "Directory";
      case MoreSys.S_IFLNK: return "Symlink";
      case MoreSys.S_IFSOCK: return "Socket";
      case MoreSys.S_IFIFO: return "FIFO/pipe";
      case MoreSys.S_IFBLK: return "Block Device";
      case MoreSys.S_IFCHR: return "Character Device";
      default: return "Unknown";
    }
  }

  String get octal {
    var a = [], i = mode, s;
    while (i > 7) {
      a.add(i.remainder(8));
      i = i ~/ 8;
    }
    s = i.toString();
    for (i = a.length - 1; i >= 0; i--) {
      s += a[i].toString();
    }
    return s;
  }

  String toString() {
    return "StatMode(modeTranslated: ${inspect(modeTranslated)}, "
        "octal: ${inspect(octal)})";
  }

}*/
