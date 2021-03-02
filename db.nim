import tables, asyncdispatch
import couch, list

type
  BDatabase* = ref object of RootObj #of RootObj needed for inheritance
    name*: string
    lists: Table[string, BList]

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

proc getDBObj(dbd: DBDirector, dbname: string): BDatabase =
  result = dbd.dbs[dbname]

proc registerCouchDB*(dbd: DBDirector, name: string, serveradr: string, user: string, password: string): CouchDatabase =
  var ndb = CouchDatabase()
  ndb.name = name
  ndb.lists = initTable[string, BList]()
  ndb.client = newCouchClient(serveradr, user, password)
  dbd.dbs[name] = ndb
  result = ndb

proc getListObj(db: BDatabase, name: string): BList =
  result = db.lists[name]

proc registerList*(db: CouchDatabase, name: string, document: string, view: string) =
  var nlist = newCouchList(document, view)
  db.lists[name] = nlist

proc queryList*(db: CouchDatabase, listname: string): Future[string] {.async.} =
  let list = db.getListObj(listname)
  result = await db.client.getDocumentStr(db.name, CouchList(list).srcdoc, CouchList(list).srcview)

proc queryList*(dbd: DBDirector, dbname: string, listname: string): Future[string]  {.async.} =
  let db = dbd.getDBObj(dbname)

  if(db of CouchDatabase):
    var res = await CouchDatabase(db).queryList(listname)
    result = res