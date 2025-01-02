#include "MongoDB_UDF\MongoDB_Test.au3"
#include "MongoDB_UDF\MongoDB.au3"

_Mongo_Init(@ScriptDir & "\MongoDB_UDF")
_MongoRunTests()

;db.createUser({user:'ffastrans', pwd: 'ffasTrans', roles:["userAdminAnyDatabase","readWriteAnyDatabase"]})
;Local $small_jsonstr = '{"path":"/folder/subfolder/fname.json","wf_id":"0230625-1518-1896-1790-0dda9dfc0f34"}'


