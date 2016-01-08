

public class Momentum {

  public static func listen(port: UInt16, hostName: String = "127.0.0.1",
      handler: (req: Request, res: Response) -> Void) throws {
    try doListen(port, hostName: hostName) { socket in
      defer { socket.close() }
      do {
        let request = try Request(socket: socket)
        if request.isReady {
          let response = Response(socket: socket)
          handler(req: request, res: response)
          response.doFlush()
        }
      } catch {
        // For now, just ignore it. Could be handled better.
        // It helps to catch it here so that it does not complicate
        // the callback code with a throw clause.
      }
    }
  }

  public static func doListen(port: UInt16, hostName: String = "127.0.0.1",
      handler: (socket: Socket) -> Void) throws {
    let server = try ServerSocket(hostName: hostName, port: port)
    while true {
      try server.spawnAccept(handler)
    }
  }

}


public class Request: CustomStringConvertible {

  var header: Header?

  init(socket: Socket) throws {
    var headerParser = HeaderParser()
    let len = 1024
    var buffer = [UInt8](count: len, repeatedValue: 0)
    var n = 0
    repeat {
      n = socket.read(&buffer, maxBytes: len)
      if n > 0 {
        do {
          try headerParser.parse(buffer, maxBytes: n)
          header = headerParser.header
        } catch {
          break
        }
      }
    } while n > 0 && !headerParser.isDone
  }

  public var method: String { return header!.method }

  public var uri: String { return header!.uri }

  public var httpVersion: String { return header!.httpVersion }

  public var fields: [String: String] { return header!.fields }

  public subscript(key: String) -> String? { return header![key] }

  public var isReady: Bool { return header != nil }

  public var description: String {
    return "Request(method: \(inspect(method)), " +
        "uri: \(inspect(uri)), " +
        "httpVersion: \(inspect(httpVersion)), " +
        "fields: \(inspect(fields)))"
  }

}


public class Response {

  public let socket: Socket
  public var statusCode = 200
  public var fields: [String: String] = ["Content-Type": "text/html"]
  var contentQueue = [[UInt8]]()
  var contentLength = 0

  init(socket: Socket) {
    self.socket = socket
  }

  public func writeHead(statusCode: Int, fields: [String: String]) {
    self.statusCode = statusCode
    self.fields = fields
  }

  public func write(string: String) {
    let a = [UInt8](string.utf8)
    contentQueue.append(a)
    contentLength += a.count
  }

  public func writeBytes(bytes: [UInt8]) {
    contentLength += bytes.count
    contentQueue.append(bytes)
  }

  public func sendFile(path: String) throws {
    writeBytes(try IO.readBytes(path))
  }

  func concatFields() -> String {
    var s = ""
    for (k, v) in fields {
      s += "\(k): \(v)\r\n"
    }
    return s
  }

  public func doFlush() {
    socket.write("HTTP/1.1 \(statusCode) \(STATUS_CODE[statusCode])" +
        "\r\n\(concatFields())Content-Length: \(contentLength)\r\n\r\n")
    for a in contentQueue {
      socket.writeBytes(a, maxBytes: a.count)
    }
  }

}


public let STATUS_CODE: [Int: String] = [
  100: "Continue",
  101: "Switching Protocols",
  200: "OK",
  201: "Created",
  202: "Accepted",
  203: "Non-Authoritative Information",
  204: "No Content",
  205: "Reset Content",
  206: "Partial Content",
  300: "Multiple Choices",
  301: "Moved Permanently",
  302: "Found",
  303: "See Other",
  304: "Not Modified",
  305: "Use Proxy",
  306: "(Unused)",
  307: "Temporary Redirect",
  400: "Bad Request",
  401: "Unauthorized",
  402: "Payment Required",
  403: "Forbidden",
  404: "Not Found",
  405: "Method Not Allowed",
  406: "Not Acceptable",
  407: "Proxy Authentication Required",
  408: "Request Timeout",
  409: "Conflict",
  410: "Gone",
  411: "Length Required",
  412: "Precondition Failed",
  413: "Request Entity Too Large",
  414: "Request-URI Too Long",
  415: "Unsupported Media Type",
  416: "Requested Range Not Satisfiable",
  417: "Expectation Failed",
  500: "Internal Server Error",
  501: "Not Implemented",
  502: "Bad Gateway",
  503: "Service Unavailable",
  504: "Gateway Timeout",
  505: "HTTP Version Not Supported"
]
