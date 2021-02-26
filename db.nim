import json, tables
import couch

type
  BDatabase* = ref object of RootObj #of RootObj needed for inheritance
    name: string

  CouchDatabase* = ref object of BDatabase
    client: CouchClient

  PostgresDatabase* = ref object of BDatabase
    serveradr: string

type
  DBDirector* = ref object
    dbs: Table[string, BDatabase]

proc newDBDirector*(): DBDirector =
  var dbd = DBDirector()
  result = dbd

proc registerCouchDB*(dbd: DBDirector, name: string, serveradr: string, user: string, password: string) =
  var ndb: BDatabase
  ndb = CouchDatabase()
  ndb.name = name
  CouchDatabase(ndb).client = newCouchClient(serveradr, user, password)
  dbd.dbs[name] = ndb

proc getDB*(dbd: DBDirector, dbname: string): BDatabase =
  result = dbd.dbs[dbname]

proc getListStr*(dbd: DBDirector, dbname: string, listname: string): string =
  let db = getDB(dbd, dbname)

  if(db of CouchDatabase):
    result = CouchDatabase(db).client.getDocumentStr(dbname, listname, listname & "-view")

proc getList*(dbd: DBDirector, dbname: string, listname: string): JsonNode =
  let db = getDB(dbd, dbname)

  if(db of CouchDatabase):
    result = CouchDatabase(db).client.getDocument(dbname, listname, listname & "-view")