import asynchttpserver, asyncdispatch

type
  HttpServer* = ref object
    aserver: AsyncHttpServer
    port: int
    cb: proc(req: Request): Future[void] {.closure, gcsafe.} 

proc newHttpServer*(port: int, callback: proc(req: Request): Future[void] {.closure, gcsafe.}): HttpServer =
  var server = HttpServer()
  server.aserver = newAsyncHttpServer()
  server.port = port
  server.cb = callback
  result = server

#proc serveCallback(req: Request) {.async.} =
#  await req.respond(Http200, "Hello Wrold")

proc serve*(server: HttpServer) =
  #waitFor server.aserver.serve(Port(server.port), serveCallback)
  waitFor server.aserver.serve(Port(server.port), server.cb)