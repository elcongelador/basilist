import tables, asyncdispatch
import couch, list

type
  QueryOptions* = tuple
    key: string
    startkey: string
    endkey: string

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

proc newQueryOptions*(key = "", startkey = "", endkey = ""): QueryOptions =
  result = (key: key, startkey: startkey, endkey: endkey)

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

proc getListObj*(dbd: DBDirector, dbname: string, listname: string): BList =
  let db = dbd.getDBObj(dbname)
  result = db.lists[listname]

proc getListObj*(db: BDatabase, listname: string): BList =
  result = db.lists[listname]

proc query*(db: CouchDatabase, listname: string, options: QueryOptions): Future[string] {.async.} =
  let list = db.getListObj(listname)
  result = await db.client.query(db.name, CouchList(list).srcdoc, CouchList(list).srcview, options)

proc query*(db: BDatabase, listname: string, options: QueryOptions, storeResult = false): Future[string]  {.async.} =
  if(db of CouchDatabase):
    if storeResult:
      getListObj(db, listname).lastresult = await CouchDatabase(db).query(listname, options)
      result = getListObj(db, listname).lastresult
    else:
      result = await CouchDatabase(db).query(listname, options)

proc query*(dbd: DBDirector, dbname: string, listname: string, options: QueryOptions, storeResult = false): Future[string]  {.async.} =
  let db = dbd.getDBObj(dbname)
  result = await db.query(listname, options, storeResult)

proc cacheList*(db: BDatabase, listname: string) =
  discard waitFor db.query(listname, newQueryOptions(), true)
  var list = db.getListObj(listname)
  list.cacheResult()

proc registerList*(db: CouchDatabase, name: string, document: string, view: string, prefetch = false) =
  echo("db.registerList: " & name)
  var nlist = newCouchList(name, document, view)
  db.lists[name] = nlist
  if prefetch: db.cacheList(name)