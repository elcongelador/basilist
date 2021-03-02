import asynchttpserver, asyncdispatch
import config, db, httpd

var dbd {.threadvar.}: DBDirector

type
  Agent* = ref object
    dbd: DBDirector
    server*: HttpServer

proc serverCallback(req: Request) {.async.} =
  let repath = parseURL(req.url.path)
  echo(repath)
  let res = await dbd.query(repath.db, repath.list)
  echo(res)
  let headers = {
    "Content-type": "application/json; charset=utf-8"
  }
  await req.respond(Http200, res, headers.newHttpHeaders(true))

proc newAgent*(): Agent =
  var ag = Agent()
  dbd = newDBDirector()
  var dbtest = dbd.registerCouchDB("test", CONF_DB_SERVERADR, CONF_DB_USER, CONF_DB_PASSWORD)
  dbtest.registerList("authors", "authors", "authors-view")

  ag.server = newHttpServer(CONF_SERVER_PORT, serverCallback)
  result = ag

proc startHttpServer*(ag: Agent) =
  ag.server.serve()