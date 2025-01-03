#include "MongoDB_UDF\MongoDB_Test.au3"
#include "MongoDB_UDF\MongoDB.au3"

_Mongo_Init(@ScriptDir & "\MongoDB_UDF")
;_MongoRunTests()

;db.createUser({user:'ffastrans', pwd: 'ffasTrans', roles:["userAdminAnyDatabase","readWriteAnyDatabase"]})
;Local $small_jsonstr = '{"path":"/folder/subfolder/fname.json","wf_id":"0230625-1518-1896-1790-0dda9dfc0f34"}'


Local $s_mongo_url 		= "mongodb://localhost:27017"
Local $s_mongo_database_name 	= "testdb"
Local $s_mongo_collection_name 	= "testcollection"
Local $sResult

;Initialize mongodb driver
Local $pMongocollection = _Mongo_CreateCollection($s_mongo_url, $s_mongo_database_name, $s_mongo_collection_name)
$sResult = _Mongo_FindMany($pMongocollection, "{}", "{}")

Local $sNext
While (_Mongo_CursorNext($sResult,$sNext))
	ConsoleWrite("FindMany Next: " & $sNext & @CRLF)
	$sNext = ""
WEnd
;Release cursor
_Mongo_CursorDestroy($sResult)