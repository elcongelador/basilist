#import json, asynchttpserver, asyncdispatch
#import db, httpd
import httpd #if we don't do this, agt.server.serve() is undeclared
import agent



let agt = newAgent()
agt.server.serve()
#agt.startHttpServer()


#var dbclient {.threadvar.}: DBClient
#dbclient = newDBClient("http://188.166.48.211:5984", "herbert", "spearmint1_fox")
#
#let res = dbclient.getList("couch::test::authors::authors-view")
#echo(res)
#
#proc cb(req: Request) {.async.} =
#  #await req.respond(Http200, "Hello Wrold")
#  let res = dbclient.getListStr("couch::test::authors::authors-view")
#  echo(res)
#  await req.respond(Http200, res)
#
#let server = newHttpServer(8080, cb)
#server.serve()