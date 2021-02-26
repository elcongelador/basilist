import asynchttpserver, asyncdispatch
import db, httpd

const CONF_DB_SERVERADR = "http://188.166.48.211:5984"
const CONF_DB_USER = "herbert"
const CONF_DB_PASSWORD = "spearmint1_fox"
const CONF_SERVER_PORT = 8080

var dbd {.threadvar.}: DBDirector

type
  Agent* = ref object
    dbd: DBDirector
    server*: HttpServer

proc serverCallback(req: Request) {.async.} =
  let list = parseURL(req.url.path)
  echo(list)
  let res = dbd.getListStr(list.db, list.list)
  echo(res)
  let headers = {
    "Content-type": "application/json; charset=utf-8"
  }
  await req.respond(Http200, res, headers.newHttpHeaders(true))

proc newAgent*(): Agent =
  var ag = Agent()
  dbd = newDBDirector()
  dbd.registerCouchDB("test", CONF_DB_SERVERADR, CONF_DB_USER, CONF_DB_PASSWORD)
  ag.server = newHttpServer(CONF_SERVER_PORT, serverCallback)
  result = ag

proc startHttpServer*(ag: Agent) =
  ag.server.serve()