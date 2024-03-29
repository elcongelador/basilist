import httpclient, base64
import asyncdispatch
import oids

type
  CouchClient* = ref object
    httpclient: AsyncHttpClient
    serveradr: string

proc newCouchClient*(serveradr: string, user: string, password: string): CouchClient =
  var client = CouchClient()
  var encoded = encode(user & ":" & password)
  client.serveradr = serveradr
  client.httpclient = newAsyncHttpClient()
  client.httpclient.headers = newHttpHeaders({ "Authorization": "Basic " & encoded })
  result = client

proc strQueryParameters(params: seq[(string, string)]): string =
  var res: string

  for i, v in params:
    if len(v[0]) > 0 and len(v[1]) > 0:
      if len(res) > 0: res.add("&")
      res.add(v[0] & "=" & v[1])

  if len(res) > 0:
    res = "?" & res

  result = res

#when using query parameters(key, startkey, endkey, ...) make sure to quote strings when type in CouchDB is a string
#for example: key="Jupiter" for a string in contrast to integers: key=1234
proc queryView*(client: CouchClient, db: string, ddoc: string, view: string, params: seq[(string, string)]): Future[string] {.async.} =
  #http://188.166.48.211:5984/test/_design/authors/_view/authors-view
  var rstr = client.serveradr & "/" & db & "/_design/" & ddoc & "/_view/" & view
  rstr.add(strQueryParameters(params))
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
  echo("couch.put (generated id): " & rstr)

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