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
  var reslist = await dbd.query(repath.db, repath.list, qopts)
  #echo(res)
  let headers = {
    "Content-type": "application/json; charset=utf-8"
  }
  await req.respond(Http200, reslist.lastresult, headers.newHttpHeaders(true))
  dbd.getListObj(repath.db, repath.list).cacheResult()

proc newAgent*(): Agent =
  var ag = Agent()
  dbd = newDBDirector()

  #var dbtest = dbd.registerCouchDB("test", CONF_DB_SERVERADR, CONF_DB_USER, CONF_DB_PASSWORD)
  #dbtest.registerList("authors", "authors", "authors-view")

  var dbperf = dbd.registerCouchDB("test_performance", CONF_DB_SERVERADR, CONF_DB_USER, CONF_DB_PASSWORD)
  dbperf.registerList("persons", "persons", "all", true)
  dbperf.registerList("locations", "locations", "all", true)
  dbperf.registerList("event_types", "event_types", "all", true)
  dbperf.registerList("persons_name", "persons", "key_name")
  dbperf.registerList("events", "events", "all")

  ag.server = newHttpServer(CONF_SERVER_PORT, serverCallback)
  result = ag

proc startHttpServer*(ag: Agent) =
  ag.server.serve()