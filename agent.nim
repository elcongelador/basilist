import asynchttpserver, asyncdispatch
import config, db, httpd, list

var dbd {.threadvar.}: DBDirector

type
  Agent* = ref object
    dbd: DBDirector
    server*: HttpServer

proc serverCallback(req: Request) {.async.} =
  echo("--- REQUEST ---")
  let rpath = parseURLPath(req.url.path)
  echo(rpath)

  case req.reqMethod
  of HttpGet: #QUERY
    echo("GET")
    let opts = parseURLQuery(req.url.query)
    echo(opts)
    let qopts = newQueryOptions(opts.key, opts.startkey, opts.endkey)
    var reslist = await dbd.query(rpath.db, rpath.list, qopts)

    let headers = {
      "Content-type": "application/json; charset=utf-8"
    }
    await req.respond(Http200, reslist.resultString, headers.newHttpHeaders(true))
    #dbd.getListObj(rpath.db, rpath.list).cacheResult()
  of HttpPut: #INSERT
    echo("PUT")
    echo(req.body)
    var res = await dbd.insert(rpath.db, rpath.list, req.body)
    echo(res)

    let headers = {
      "Content-type": "application/json; charset=utf-8"
    }
    await req.respond(Http200, res, headers.newHttpHeaders(true))
  of HttpPost: #UPDATE
    echo("POST")
    echo(req.body)
    var res = await dbd.update(rpath.db, rpath.list, rpath.id, req.body)
    echo(res)

    let headers = {
      "Content-type": "application/json; charset=utf-8"
    }
    await req.respond(Http200, "{\"ok\":\"true\"}", headers.newHttpHeaders(true))
  of HttpDelete: #DELETE
    echo("DELETE")
    let opts = parseURLQuery(req.url.query)
    echo(opts)
    var res = await dbd.delete(rpath.db, rpath.list, rpath.id, opts.rev)
    echo(res)

    let headers = {
      "Content-type": "application/json; charset=utf-8"
    }
    await req.respond(Http200, res, headers.newHttpHeaders(true))
    #await req.respond(Http200, "{\"ok\":\"true\"}", headers.newHttpHeaders(true))
  else:
    discard

proc newAgent*(): Agent =
  var ag = Agent()
  dbd = newDBDirector()

  var dbtest = dbd.registerCouchDB("test", CONF_DB_SERVERADR, CONF_DB_USER, CONF_DB_PASSWORD)
  discard dbtest.registerList("authors", "authors", "authors-view")

  var dbperf = dbd.registerCouchDB("test_performance", CONF_DB_SERVERADR, CONF_DB_USER, CONF_DB_PASSWORD)
  #discard dbperf.registerList("persons_name", "persons", "key_name")
  var perlist =  dbperf.registerList("persons", "persons", "all")
  discard dbperf.registerList("locations", "locations", "all")
  var evtplist = dbperf.registerList("event_types", "event_types", "all")
  var evlist = dbperf.registerList("events", "events", "all", true)
  evlist.addFieldReference(("person_id", perlist, "display_name"))
  evlist.addFieldReference(("event_type_id", evtplist, "name"))
  dbperf.prefetchReferences()

  var dbtestsuite = dbd.registerCouchDB("testsuite", CONF_DB_SERVERADR, CONF_DB_USER, CONF_DB_PASSWORD)
  discard dbtestsuite.registerList("authors", "authors", "authors-view")

  ag.server = newHttpServer(CONF_SERVER_PORT, serverCallback)
  result = ag

proc startHttpServer*(ag: Agent) =
  ag.server.serve()