import json

type
  BList* = ref object
    name: string
    srcdoc: string
    srcview: string
    rows: JsonNode