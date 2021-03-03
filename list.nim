#import json
import tables, json
import std/monotimes

type
  BList* = ref object of RootObj #of RootObj needed for inheritance
    name*: string
    #rows: JsonNode 
    cache: Table[string, JsonNode]
    lastresult*: string

  CouchList* = ref object of BList
    srcdoc*: string
    srcview*: string

  PostgresList* = ref object of BList
    srctable*: string

proc newCouchList*(document: string, view: string): CouchList =
  var cl = CouchList()
  cl.srcdoc = document
  cl.srcview = view
  cl.cache = initTable[string, JsonNode]()
  result = cl

proc cacheResult*(list: CouchList) =
  let a = getMonoTime()

  var jsonResult = parseJson(list.lastresult)
  for row in jsonResult["rows"]:
    let key = row["id"].getStr()
    list.cache[key] = row["value"]

  let b = getMonoTime()

  let duration = b - a
  echo(duration)

proc cacheResult*(list: BList) =
  if list of CouchList:
    CouchList(list).cacheResult()
