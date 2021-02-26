#import json
import tables

type
  BList* = ref object of RootObj #of RootObj needed for inheritance
    name: string
    srcdb: string
    #rows: JsonNode

  CouchList* = ref object of BList
    srcdoc: string
    srcview: string

  PostgresList* = ref object of BList
    srctable: string

type
  ListType* = enum
    ltCouchList, ldPostgresList

type
  ListDirector* = ref object
    lists: Table[string, BList]

proc newListDirector*(): ListDirector =
  var ld = ListDirector()
  result = ld

proc addList*(ld: ListDirector, ltype: ListType, dbname: string, listname: string) =
  var nlist: BList

  case ltype:
    of ltCouchList:
      nlist = CouchList()
      CouchList(nlist).srcdoc = listname
      Couchlist(nlist).srcview = listname & "-view"
    of ldPostgresList:
      nlist = PostgresList()
      PostgresList(nlist).srctable = listname

  nlist.name = listname
  nlist.srcdb = dbname
  ld.lists[dbname & "__" & listname] = nlist

proc getList*(ld: ListDirector, dbname: string, listname: string): BList =
  result = ld.lists[dbname & "__" & listname]

when isMainModule:
  let ld = newListDirector()
  ld.addList(ltCouchList, "somedb", "testlist")
  let alist = ld.getList("somedb", "testlist")

  echo(alist.srcdb)

  if(alist of CouchList):
    echo(CouchList(alist).srcdoc)
