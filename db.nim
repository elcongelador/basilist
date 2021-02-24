import json
import couch

type
  DBClient* = ref object
    couch: CouchClient

proc newDBClient*(serveradr: string, user: string, password: string): DBClient =
  var client = DBClient()
  client.couch = newCouchClient(serveradr, user, password)
  result = client

#list parameter example: couch::test::authors::authors-view
proc getList*(client: DBClient, list: string): JsonNode =
  result = client.couch.getDocument("test", "authors", "authors-view")

proc getListStr*(client: DBClient, list: string): string =
  result = client.couch.getDocumentStr("test", "authors", "authors-view")