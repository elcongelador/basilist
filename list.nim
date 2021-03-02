#import json
import tables, json

type
  BList* = ref object of RootObj #of RootObj needed for inheritance
    name*: string
    #rows: JsonNode 
    cache: Table[string, JsonNode]

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