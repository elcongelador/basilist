import asynchttpserver, asyncdispatch
import config, db, httpd, list, tables, sugar

var dbd {.threadvar.}: DBDirector

type
  Agent* = ref object
    dbd: DBDirector
    server*: HttpServer

proc serverCallback(req: Request) {.async.} =
  echo("--- REQUEST ---")
  let rpath = parseURLPath(req.url.path)
  echo(rpath)
  let rquery = parseURLQuery(req.url.query)

  case req.reqMethod
  of HttpGet: #QUERY
    echo("GET")
    let headers = {
      "Content-type": "application/json; charset=utf-8"
    }

    if not rquery.hasKey("query"):
      echo("returning error: bad request, reason: No query parameter.")
      await req.respond(Http400, "{\"error\":\"bad request\",\"reason\":\"No query parameter.\"}", headers.newHttpHeaders(true))
      break

    #split rquery table into query name and seq of params here
    #let params = collect(newSeq, for k, v in rquery.pairs: (k, v))

    let params = collect(newSeq):
      for k, v in rquery.pairs:
        if k != "query": (k, v)

    echo(rquery)
    echo(params)

    try:
      var reslist = await dbd.read(rpath.db, rpath.list, rquery["query"], params)
      await req.respond(Http200, reslist.resultString, headers.newHttpHeaders(true))
    except KeyError:
      echo("Exception: " & getCurrentExceptionMsg())
      await req.respond(Http400, "{\"error\":\"bad request\",\"reason\":\"" & getCurrentExceptionMsg() & "\"}", headers.newHttpHeaders(true))

    #dbd.getListObj(rpath.db, rpath.list).cacheResult()
  of HttpPut: #INSERT
    echo("PUT")
    echo(req.body)
    var res = await dbd.create(rpath.db, rpath.list, req.body)
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
    await req.respond(Http200, res, headers.newHttpHeaders(true))
  of HttpDelete: #DELETE
    echo("DELETE")
    var res = await dbd.delete(rpath.db, rpath.list, rpath.id, rquery["rev"])
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

  #[
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
  ]#

  var dbtestsuite = dbd.registerCouchDB("testsuite", CONF_DB_SERVERADR, CONF_DB_USER, CONF_DB_PASSWORD)
  var authlist =  dbtestsuite.registerList("authors", "authors", "key_name")
  authlist.registerQuery(CouchQuery(name: "key_name", qtype: qtRead, document: "authors", view: "key_name"))

  ag.server = newHttpServer(CONF_SERVER_PORT, serverCallback)
  result = ag

proc startHttpServer*(ag: Agent) =
  ag.server.serve()