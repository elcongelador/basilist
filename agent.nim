import asynchttpserver, asyncdispatch
import db, httpd

const CONF_DB_SERVERADR = "http://188.166.48.211:5984"
const CONF_DB_USER = "herbert"
const CONF_DB_PASSWORD = "spearmint1_fox"
const CONF_SERVER_PORT = 8080

var dbclient {.threadvar.}: DBClient

type
  Agent* = ref object
    dbclient: DBClient
    server*: HttpServer

proc serverCallback(req: Request) {.async.} =
  let src = parseURL(req.url.path)
  echo(src)
  let res = dbclient.getCouchListStr("couch::test::authors::authors-view")
  echo(res)
  let headers = {
    "Content-type": "application/json; charset=utf-8"
  }
  await req.respond(Http200, res, headers.newHttpHeaders(true))

proc newAgent*(): Agent =
  var ag = Agent()
  dbclient = newDBClient(CONF_DB_SERVERADR, CONF_DB_USER, CONF_DB_PASSWORD)
  ag.dbclient = dbclient
  ag.server = newHttpServer(CONF_SERVER_PORT, serverCallback)
  result = ag

proc startHttpServer*(ag: Agent) =
  ag.server.serve()