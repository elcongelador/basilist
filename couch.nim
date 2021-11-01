import httpclient, base64
import asyncdispatch
import oids

type
  CouchQueryOptions* = tuple
    key: string
    startkey: string
    endkey: string

type
  CouchClient* = ref object
    httpclient: AsyncHttpClient
    serveradr: string

proc newCouchQueryOptions*(key = "", startkey = "", endkey = ""): CouchQueryOptions =
  result = (key: key, startkey: startkey, endkey: endkey)

proc newCouchClient*(serveradr: string, user: string, password: string): CouchClient =
  var client = CouchClient()
  var encoded = encode(user & ":" & password)
  client.serveradr = serveradr
  client.httpclient = newAsyncHttpClient()
  client.httpclient.headers = newHttpHeaders({ "Authorization": "Basic " & encoded })
  result = client

proc strQueryOptions(options: CouchQueryOptions): string =
  var res: string

  if len(options.key) > 0:
    res.add("key=" & options.key)

  if len(options.startkey) > 0:
    if len(res) > 0: res.add("&")
    res.add("startkey=" & options.startkey)

  if len(options.endkey) > 0:
    if len(res) > 0: res.add("&")
    res.add("endkey=" & options.endkey)

  if len(res) > 0:
    res = "?" & res

  result = res

proc query*(client: CouchClient, db: string, ddoc: string, view: string, options: CouchQueryOptions): Future[string] {.async.} =
  #http://188.166.48.211:5984/test/_design/authors/_view/authors-view
  var rstr = client.serveradr & "/" & db & "/_design/" & ddoc & "/_view/" & view
  rstr.add(strQueryOptions(options))
  echo("couch.query: " & rstr)
  try:
    result = await client.httpclient.getContent(rstr)
    #NOTE: we have to close the connection here, because if we don't it stays open and then the server might
    #close it after some time of inactivity (which results in a ProctoclError: Connection was closed)
    #(leaving it open may be useful (performance!) if we have have many subsequent requests, but not here)
    client.httpclient.close() #occasional ProtocolErros if we don't do this
  except ProtocolError:
    echo "ProtocolError!"

#proc getDocument*(client: CouchClient, db: string, ddoc: string, view: string): Future[JsonNode] {.async.} =
#  let response = await client.query(db, ddoc, view)
#  result = parseJson(response)

#create a new document; automatically generates _id
proc put*(client: CouchClient, db: string, doc: string): Future[string] {.async.} =
  let uuid = $(genOid())
  #doc["_id"] = %* uuid #JsonNode
  var rstr = client.serveradr & "/" & db & "/" & uuid
  echo("couch.post: " & rstr)

  try:
    var res = await client.httpclient.putContent(rstr, $(doc))
    client.httpclient.close() #occasional ProtocolErros if we don't do this
    result = res
  except ProtocolError:
    echo "ProtocolError!"

#create a new document with id
#if documents with id exists and rev ist in doc argument, it will be updated
proc put*(client: CouchClient, db: string, id: string, doc: string): Future[string] {.async.} =
  var rstr = client.serveradr & "/" & db & "/" & id
  echo("couch.put: " & rstr)

  try:
    var res = await client.httpclient.putContent(rstr, $(doc))
    client.httpclient.close() #occasional ProtocolErros if we don't do this
    result = res
  except ProtocolError:
    echo "ProtocolError!"

#delete a document
proc delete*(client: CouchClient, db: string, id: string, rev: string): Future[string] {.async.} =
  var rstr = client.serveradr & "/" & db & "/" & id & "?rev=" & rev
  echo("couch.delete: " & rstr)

  try:
    var res = await client.httpclient.deleteContent(rstr)
    client.httpclient.close() #occasional ProtocolErros if we don't do this
    result = res
  except ProtocolError:
    echo "ProtocolError!"


#when isMainModule:
  #let client = newCouchClient("http://x.x.x.x:5984", "user", "password")
  #let res = client.getDocument("test", "authors", "authors-view")
  #echo(res)