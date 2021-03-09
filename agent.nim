import asynchttpserver, asyncdispatch
import config, db, httpd, list

var dbd {.threadvar.}: DBDirector

type
  Agent* = ref object
    dbd: DBDirector
    server*: HttpServer

proc serverCallback(req: Request) {.async.} =
  echo("--- REQUEST ---")
  let repath = parseURLPath(req.url.path)
  let opts = parseURLQuery(req.url.query)
  echo(repath)
  echo(opts)
  let qopts = newQueryOptions(opts.key, opts.startkey, opts.endkey)
  let res = await dbd.query(repath.db, repath.list, qopts, true)
  #echo(res)
  let headers = {
    "Content-type": "application/json; charset=utf-8"
  }
  await req.respond(Http200, res, headers.newHttpHeaders(true))
  dbd.getListObj(repath.db, repath.list).cacheResult()

proc newAgent*(): Agent =
  var ag = Agent()
  dbd = newDBDirector()
  var dbtest = dbd.registerCouchDB("test", CONF_DB_SERVERADR, CONF_DB_USER, CONF_DB_PASSWORD)
  dbtest.registerList("authors", "authors", "authors-view")
  var dbperf = dbd.registerCouchDB("test_performance", CONF_DB_SERVERADR, CONF_DB_USER, CONF_DB_PASSWORD)
  dbperf.registerList("persons", "persons", "all")
  dbperf.registerList("persons_name", "persons", "key_name")
  dbperf.registerList("events", "events", "all")

  ag.server = newHttpServer(CONF_SERVER_PORT, serverCallback)
  result = ag

proc startHttpServer*(ag: Agent) =
  ag.server.serve()