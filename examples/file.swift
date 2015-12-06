
import Glibc


class Sys {

  static func retry(fn: () -> Int) -> Int {
    var value = fn()
    while value == -1 {
      if (errno != EINTR) { break }
      value = fn()
    }
    return value
  }

}


public class File {

  static let DEFAULT_DIR_MODE = S_IRWXU | S_IRWXG | S_IRWXO

  static let DEFAULT_FILE_MODE = S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP |
      S_IROTH

}

print("File")
print(File.DEFAULT_FILE_MODE)
