#import json
import tables, json
import std/monotimes

type
  BList* = ref object of RootObj #of RootObj needed for inheritance
    name*: string
    #rows: JsonNode 
    cache: Table[string, JsonNode]
    resultString*: string
    resultJson*: JsonNode
    fieldrefs: seq[FieldReference]

  CouchList* = ref object of BList
    srcdoc*: string
    srcview*: string

  PostgresList* = ref object of BList
    srctable*: string

  FieldReference* = tuple
    field: string
    reflist: BList
    reffield: string

proc newCouchList*(name: string, document: string, view: string): CouchList =
  var cl = CouchList()
  cl.name = name
  cl.srcdoc = document
  cl.srcview = view
  cl.cache = initTable[string, JsonNode]()
  result = cl

method resultToJson*(list: BList) {.base.} =
  #echo("BList.resultToJson")
  #if list of CouchList:
  #  CouchList(list).resultToJson()
  quit "resultToJson base method called!"

method resultToJson*(list: CouchList) =
  #pragma needed to prevent compiler warning (different method lock levels because of parseJson)
  #alternatively use procedures, not methods and dispatch in base method based on type of list parameter
  {.warning[LockLevel]:off.} 
  echo("CouchList.resultToJson")
  list.resultJson = parseJson(list.resultString)

proc cacheResult*(list: CouchList) =
  echo("list.cacheResult: " & list.name)
  echo("number of cache rows (start): " & $(len(list.cache)))

  let a = getMonoTime()
  list.resultToJson()
  let b = getMonoTime()
  let duration = b - a
  echo(duration)

  for row in list.resultJson["rows"]:
    let key = row["id"].getStr()
    list.cache[key] = row["value"]

  let c = getMonoTime()

  let duration1 = c - b
  echo(duration1)

  echo("number of cache rows (end): " & $(len(list.cache)))

proc cacheResult*(list: BList) =
  if list of CouchList:
    CouchList(list).cacheResult()

proc addFieldReference*(list: BList, newref: FieldReference) =
  list.fieldrefs.add(newref)

proc hasFieldReference*(list: BList): bool =
  result = (if len(list.fieldrefs) > 0: true else: false)

proc transformList*(list: BList) =
  echo("transformList: " & list.name)
  list.resultToJson()
  
  for row in list.resultJson["rows"]:
    var rowval = row["value"]
    for fref in list.fieldrefs: #iterate through field references
      var key = rowval[fref.field]
      if key.kind == JString:
        var referedNode = fref.reflist.cache[key.getStr()] #get the refered node from cache
        rowval[fref.field & "_ref"] = referedNode[fref.reffield] #insert new node here

  #for row in list.resultJson["rows"]:
  #  echo("person_id: " & row["person_id"].getStr())

  list.resultString = $(list.resultJson)