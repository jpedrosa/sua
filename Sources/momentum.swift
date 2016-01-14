

public typealias MomentumHandler = (req: Request, res: Response) throws -> Void


public class Momentum {

  public static func listen(port: UInt16, hostName: String = "127.0.0.1",
      handler: MomentumHandler) throws {
    try doListen(port, hostName: hostName) { socket in
      defer { socket.close() }
      do {
        let request = try Request(socket: socket)
        let response = Response(socket: socket)

        // Look for static handlers.
        var handled = false
        if Momentum.haveHandlers {
          if request.method == "GET" {
            if let ah = Momentum.handlersGet[request.uri] {
              handled = true
              try ah(req: request, res: response)
            }
          } else if request.method == "POST" {
            if let ah = Momentum.handlersPost[request.uri] {
              handled = true
              try ah(req: request, res: response)
            }
          }
        }

        if !handled {
          try handler(req: request, res: response)
        }
        response.doFlush()
      } catch (let e) {
        // Ignore it. By catching the errors here the server can continue to
        // operate. The user code can catch its own errors in its handler
        // callback in case they want to log it or some such.
        print("Momentum error: \(e)")
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

  public static var haveHandlers = false

  static var handlersGet = [String: MomentumHandler]()

  public static func get(uri: String, handler: MomentumHandler) {
    handlersGet[uri] = handler
    haveHandlers = true
  }

  static var handlersPost = [String: MomentumHandler]()

  public static func post(uri: String, handler: MomentumHandler) {
    handlersPost[uri] = handler
    haveHandlers = true
  }

}


public class Request: CustomStringConvertible {

  var header: Header
  var _body: Body?

  init(socket: Socket) throws {
    var headerParser = HeaderParser()
    header = headerParser.header
    let len = 1024
    var buffer = [UInt8](count: len, repeatedValue: 0)
    var n = 0
    repeat {
      n = socket.read(&buffer, maxBytes: len)
      try headerParser.parse(buffer, maxBytes: n)
    } while n > 0 && !headerParser.isDone

    header = headerParser.header

    if n != 0 && headerParser.isDone && header.method == "POST" {
      var bodyParser = BodyParser()
      let bi = headerParser.bodyIndex
      if bi != -1 && buffer[bi] != 0 {
        try bodyParser.parse(buffer, index: bi, maxBytes: len)
      }
      if !bodyParser.isDone {
        repeat {
          n = socket.read(&buffer, maxBytes: len)
          try bodyParser.parse(buffer, index: 0, maxBytes: n)
        } while n > 0 && !bodyParser.isDone
      }
      _body = bodyParser.body
    }
  }

  public var method: String { return header.method }

  public var uri: String { return header.uri }

  public var httpVersion: String { return header.httpVersion }

  public var fields: [String: String] { return header.fields }

  public subscript(key: String) -> String? { return header[key] }

  public var body: Body? { return _body }

  public var description: String {
    return "Request(method: \(inspect(method)), " +
        "uri: \(inspect(uri)), " +
        "httpVersion: \(inspect(httpVersion)), " +
        "fields: \(inspect(fields)), " +
        "body: \(inspect(_body)))"
  }

}


public class Response {

  public let socket: Socket
  public var statusCode = 200
  public var fields = ["Content-Type": "text/html"]
  var contentQueue = [[UInt8]]()
  public var contentLength = 0
  var flushed = false

  init(socket: Socket) {
    self.socket = socket
  }

  public subscript(key: String) -> String? {
    get { return fields[key] }
    set { fields[key] = newValue }
  }

  public func write(string: String) {
    writeBytes([UInt8](string.utf8))
  }

  public func writeBytes(bytes: [UInt8]) {
    contentLength += bytes.count
    contentQueue.append(bytes)
  }

  public func sendFile(path: String) throws {
    writeBytes(try IO.readAllBytes(path))
  }

  func concatFields() -> String {
    var s = ""
    for (k, v) in fields {
      s += "\(k): \(v)\r\n"
    }
    return s
  }

  public func doFlush() {
    if flushed { return }
    socket.write("HTTP/1.1 \(statusCode) \(STATUS_CODE[statusCode])" +
        "\r\n\(concatFields())Content-Length: \(contentLength)\r\n\r\n")
    for a in contentQueue {
      socket.writeBytes(a, maxBytes: a.count)
    }
    flushed = true
  }

  public func redirectTo(url: String) {
    statusCode = 302
    fields["Location"] = url
  }

  public var contentType: String? {
    get { return fields["Content-Type"] }
    set { fields["Content-Type"] = newValue }
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
  451: "Unavailable For Legal Reasons",
  500: "Internal Server Error",
  501: "Not Implemented",
  502: "Bad Gateway",
  503: "Service Unavailable",
  504: "Gateway Timeout",
  505: "HTTP Version Not Supported"
]
