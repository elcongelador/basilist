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
  if dbd.dbs.hasKey(dbname):
    result = dbd.dbs[dbname]
  else:
    result = nil

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
  echo("db.getListObj: " & listname)
  echo("keys: ")
  for k in db.lists.keys:
    echo k

  result = db.lists[listname]

proc read*(db: CouchDatabase, list: CouchList, queryname: string, params: seq[(string, string)]): Future[BList] {.async.} =
  echo("db.query.CouchDatabase: " & list.name)
  let query = list.queries[queryname]
  list.resultString = await db.client.queryView(db.name, query.document, query.view, params)
  result = list

proc read*(db: BDatabase, listname: string, queryname: string, params: seq[(string, string)] = @[]): Future[BList]  {.async.} =
  echo("db.query.BDatabase: " & listname)
  var list = db.getListObj(listname)
  let cacheKey = listname & ":" & queryname & $params #TODO: check if this works

  if list.doCacheResults and list.cacheOfResults.hasKey(cacheKey):
    echo("cache hit")
    list.resultString = list.cacheOfResults[cacheKey]
  else:
    if(db of CouchDatabase):
        list = await CouchDatabase(db).read(CouchList(list), queryname, params)

    if list.hasFieldReference():
      list.transformList()

    if list.doCacheResults: #result was not in cache, so add it here
      list.cacheOfResults[cacheKey] = list.resultString

  result = list

proc read*(dbd: DBDirector, dbname: string, listname: string, queryname: string, params: seq[(string, string)] = @[]): Future[BList]  {.async.} =
  echo("db.query.DBDirector: " & listname)
  let db = dbd.getDBObj(dbname)
  var list = await db.read(listname, queryname, params)
  result = list

proc cacheList*(db: BDatabase, list: BList) =
  var list = waitFor(db.read(list.name, list.prefetchQuery))
  list.addResultToCache()

proc registerList*(db: CouchDatabase, name: string, document: string, view: string, cacheResults = false): CouchList =
  echo("db.registerList: " & name)
  var nlist = newCouchList(name, document, view, cacheResults)
  db.lists[name] = nlist
  result = nlist

proc prefetchReferences*(db: BDatabase) =
  for list in db.lists.values:
    for fref in list.fieldrefs:
      db.cacheList(fref.reflist)

proc create*(db: CouchDatabase, listname: string, row: string): Future[string] {.async.} =
  result = await db.client.put(db.name, row)

proc create*(db: BDatabase, listname: string, row: string): Future[string]  {.async.} =
  var list = db.getListObj(listname)

  #TODO
  #if list.doCacheResults and list.cacheOfResults.hasKey($options):
  #  echo("cache hit")

  if(db of CouchDatabase):
      result = await CouchDatabase(db).create(listname, row)

  if list.hasFieldReference():
    discard
    #TODO

  if list.doCacheResults: #result was not in cache, so add it here
    discard
    #TODO
    #list.cacheOfResults[$options] = list.resultString

proc create*(dbd: DBDirector, dbname: string, listname: string, row: string): Future[string]  {.async.} =
  let db = dbd.getDBObj(dbname)
  result = await db.create(listname, row)

proc update*(db: CouchDatabase, listname: string, id: string, row: string): Future[string] {.async.} =
  result = await db.client.put(db.name, id, row)

proc update*(db: BDatabase, listname: string, id: string, row: string): Future[string]  {.async.} =
  var list = db.getListObj(listname)

  #TODO
  #if list.doCacheResults and list.cacheOfResults.hasKey($options):
  #  echo("cache hit")

  if(db of CouchDatabase):
      result = await CouchDatabase(db).update(listname, id, row)

  if list.hasFieldReference():
    discard
    #TODO

  if list.doCacheResults: #result was not in cache, so add it here
    discard
    #TODO
    #list.cacheOfResults[$options] = list.resultString

proc update*(dbd: DBDirector, dbname: string, listname: string, id: string, row: string): Future[string]  {.async.} =
  let db = dbd.getDBObj(dbname)
  result = await db.update(listname, id, row)

proc delete*(db: CouchDatabase, listname: string, id: string, rev: string): Future[string] {.async.} =
  result = await db.client.delete(db.name, id, rev)

proc delete*(db: BDatabase, listname: string, id: string, rev: string = ""): Future[string]  {.async.} =
  var list = db.getListObj(listname)

  #TODO
  #if list.doCacheResults and list.cacheOfResults.hasKey($options):
  #  echo("cache hit")

  if(db of CouchDatabase):
      result = await CouchDatabase(db).delete(listname, id, rev)

  if list.hasFieldReference():
    discard
    #TODO

  if list.doCacheResults:
    discard
    #TODO
    #list.cacheOfResults[$options] = list.resultString

proc delete*(dbd: DBDirector, dbname: string, listname: string, id: string, rev: string = ""): Future[string]  {.async.} =
  let db = dbd.getDBObj(dbname)
  result = await db.delete(listname, id, rev)