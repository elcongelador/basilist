import asynchttpserver, asyncdispatch
import strutils, cgi

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

func parseURLPath*(url: string): auto =
  let parts = split(url, '/')

  if(len(parts) < 3 or len(parts[0]) > 0 or len(parts[1]) < 1 or len(parts[2]) < 1):
    #TODO: throw error
    #echo("ERROR: URL does not conform to /dbname/listname or /dbname/listname/id")
    discard

  var id: string
  if(len(parts) > 3): 
    id = parts[3]

  result = (db: parts[1], list: parts[2], id: id)

func parseURLQuery*(query: string): auto =
  var key, startkey, endkey: string

  for item in decodeData(query):
    if(item.key == "key"):
      key = item.value
    elif(item.key == "startkey"):
      startkey = item.value
    elif(item.key == "endkey"):
      endkey = item.value

  result = (key: key, startkey: startkey, endkey: endkey)