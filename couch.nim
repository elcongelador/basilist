import httpclient, base64, json

type
  CouchClient* = ref object
    httpclient: HttpClient
    serveradr: string

proc newCouchClient*(serveradr: string, user: string, password: string): CouchClient =
  var client = CouchClient()
  var encoded = encode(user & ":" & password)
  client.serveradr = serveradr
  client.httpclient = newHttpClient()
  client.httpclient.headers = newHttpHeaders({ "Authorization": "Basic " & encoded })
  result = client

proc getDocumentStr*(client: CouchClient, db: string, ddoc: string, view: string): string =
  #http://188.166.48.211:5984/test/_design/authors/_view/authors-view
  let rstr = client.serveradr & "/" & db & "/_design/" & ddoc & "/_view/" & view
  try:
    result = client.httpclient.getContent(rstr)
    #NOTE: we have to close the connection here, because if we don't it stays open and then the server might
    #close it after some time of inactivity (which results in a ProctoclError: Connection was closed)
    #(leaving it open may be useful (performance!) if we have have many subsequent requests, but not here)
    client.httpclient.close() #occasional ProtocolErros if we don't do this
  except ProtocolError:
    echo "ProtocolError!"

proc getDocument*(client: CouchClient, db: string, ddoc: string, view: string): JsonNode =
  let response = client.getDocumentStr(db, ddoc, view)
  result = parseJson(response)

#when isMainModule:
  #let client = newCouchClient("http://x.x.x.x:5984", "user", "password")
  #let res = client.getDocument("test", "authors", "authors-view")
  #echo(res)