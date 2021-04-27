#import json
import tables, json
import std/monotimes
import times #needed for pretty echo-output of Duration objects

type
  BList* = ref object of RootObj #of RootObj needed for inheritance
    name*: string
    doCacheResults*: bool  #enables cacheResult
    doCacheRows*: bool #enables cacheRow
    cacheOfResults*: Table[string, string] #result string cache
    cacheOfRows: Table[string, JsonNode] #row cache in json form
    resultJson*: JsonNode #last result json
    resultString*: string #last result string
    fieldrefs*: seq[FieldReference]
    cacheIsValid*: bool
    #TODO
    #insert options: auto-generate id or not

  CouchList* = ref object of BList
    srcdoc*: string
    srcview*: string

  PostgresList* = ref object of BList
    srctable*: string

  FieldReference* = tuple
    field: string
    reflist: BList
    reffield: string

proc newCouchList*(name: string, document: string, view: string, cachResults: bool): CouchList =
  var cl = CouchList()
  cl.name = name
  cl.doCacheRows = false
  cl.doCacheResults = cachResults
  cl.cacheIsValid = false

  cl.srcdoc = document
  cl.srcview = view
  cl.cacheOfRows = initTable[string, JsonNode]()
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

proc addResultToCache*(list: CouchList) =
  echo("list.addResultToCache: " & list.name)
  echo("number of cache rows (start): " & $(len(list.cacheOfRows)))

  let a = getMonoTime()
  list.resultToJson() #convert string to json object
  let b = getMonoTime()
  let duration = b - a
  echo("JSON parsing: " & $duration)

  for row in list.resultJson["rows"]: #add each row to cache
    let key = row["id"].getStr()
    list.cacheOfRows[key] = row["value"]

  let c = getMonoTime()

  let duration1 = c - b
  echo("cache building: " & $duration1)

  echo("number of cache rows (end): " & $(len(list.cacheOfRows)))

  list.cacheIsValid = true

proc addResultToCache*(list: BList) =
  if list of CouchList:
    CouchList(list).addResultToCache()

proc addFieldReference*(list: BList, newref: FieldReference) =
  list.fieldrefs.add(newref)
  newref.reflist.doCacheRows = true #reference implies cache on refered list

proc hasFieldReference*(list: BList): bool =
  result = (if len(list.fieldrefs) > 0: true else: false)

proc transformList*(list: BList) =
  echo("transformList: " & list.name)
  let a = getMonoTime()
  list.resultToJson()
  let b = getMonoTime()

  #TODO: check if caches are valid
  #if not fref.reflist.cacheIsValid: #make sure cache of refered list is valid
  
  for row in list.resultJson["rows"]:
    var rowval = row["value"]
    for fref in list.fieldrefs: #iterate through field references
      var key = rowval[fref.field]
      if key.kind == JString:
        var referedNode = fref.reflist.cacheOfRows[key.getStr()] #get the refered node from cache
        rowval[fref.field & "_ref"] = referedNode[fref.reffield] #insert new node here

  #for row in list.resultJson["rows"]:
  #  echo("person_id: " & row["person_id"].getStr())

  let c = getMonoTime()
  list.resultString = $(list.resultJson)
  let d = getMonoTime()

  echo("transformed number of rows: " & $len(list.resultJson["rows"]))
  let dur1 = b - a
  echo("JSON parsing: " & $dur1)
  let dur2 = c - b
  echo("row transformation: " & $dur2)
  let dur3 = d - c
  echo("JSON object to string: " & $dur3)