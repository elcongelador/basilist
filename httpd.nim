import asynchttpserver, asyncdispatch
import strutils

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

proc parseURL*(url: string): auto =
  let parts = split(url, '/')

  if(len(parts) < 3 or len(parts[0]) > 0 or len(parts[1]) < 1 or len(parts[2]) < 1):
    #throw error
    echo("ERROR: URL does not conform to /dbname/listname")

  result = (db: parts[1], list: parts[2])