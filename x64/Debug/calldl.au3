#AutoIt3Wrapper_UseX64=Y
#include <C:\dev\FFAStrans\Processors\JSON.au3>
#include <WinAPIError.au3>
;C:\Users\Gam3r1\AppData\Local\Temp\mongod.exe --dbpath C:\temp\filebrdg
Opt("MustDeclareVars", 1)

Global Const $g_sFileDll    = 'C:\dev\FileBridge++\FileBridge++\x64\Debug\MongoCBridge.dll'

Global $s_mongo_url 		= "mongodb://localhost:27017"
Global $s_mongo_database_name 	= "harrysDB"
Global $s_mongo_collection_name 	= "testcollection"

Local $jsonstr = '{"path":"/folder/subfolder/fname.json","content":{"jsoncont":"no"}}'

Local $hdll = DllOpen($g_sFileDll)
MsgBox(0,"","")
Local $ptr_mongocollection = CreateCollection($s_mongo_url, $s_mongo_database_name, $s_mongo_collection_name)


UpdateOne($ptr_mongocollection, '{"path":"/folder/subfolder/fname.json"}','{"$set":'&$jsonstr&'}','{"upsert":true}')
FindOne($ptr_mongocollection, '{"path":"/folder/subfolder/fname.json"}')
DeleteOne($ptr_mongocollection, '{"path":"/folder/subfolder/fname.json"}')

;~ Local $j = Json_ObjCreate()
;~ Json_ObjPut($j, "filename","thatfile")
;~ Json_ObjPut($j, "content", $utf16String)
;~ $utf16String = Json_Encode($j)
;~ InsertOne($ptr_mongocollection, $utf16String)

;;
;; MongoBridge Functions
;;
Func CreateCollection($s_mongoconnectionstr, $s_mongo_database_name, $s_mongo_collection_name)
	;~ if DB is offline, we still get a valid collection that works once the db comes online
	Local $constr_ptr = DllStructCreate("wchar [" & StringLen($s_mongoconnectionstr) + 1 & "]") ; +1 for null terminator
	DllStructSetData($constr_ptr, 1, $s_mongoconnectionstr)
	Local $dbname_ptr = DllStructCreate("wchar [" & StringLen($s_mongo_database_name) + 1 & "]") ; +1 for null terminator
	DllStructSetData($dbname_ptr, 1, $s_mongo_database_name)
	Local $colname_ptr = DllStructCreate("wchar [" & StringLen($s_mongo_collection_name) + 1 & "]") ; +1 for null terminator
	DllStructSetData($colname_ptr, 1, $s_mongo_collection_name)
	Local $a_result = DllCall($hdll, "ptr", "CreateCollection", "ptr", DllStructGetPtr($constr_ptr),"ptr", DllStructGetPtr($dbname_ptr),"ptr", DllStructGetPtr($colname_ptr));
	ConsoleWrite("CreateCollection: " & $a_result[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
	return $a_result[0]
EndFunc

Func InsertOne($ptr_mongocollection,$s_json)
	Local $struct = DllStructCreate("wchar [" & StringLen($s_json) + 1 & "]") ; +1 for null terminator
	DllStructSetData($struct, 1, $s_json)
	Local $a_insertresult = DllCall($hdll, "int:cdecl", "InsertOne", "ptr", $ptr_mongocollection, "ptr",DllStructGetPtr($struct))
	ConsoleWrite("InsertResult: " & $a_insertresult[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
EndFunc

Func UpdateOne($ptr_mongocollection, $search, $update, $options)
	;~https://www.mongodb.com/docs/manual/reference/method/db.collection.updateOne/
	;~commonly used options: {"upsert":true}
	;~returns json str like { "modifiedCount" : 1, "matchedCount" : 1, "upsertedCount" : 0 }
	Local $_searchptr
	MakeWstrPtr($_searchptr,$search)
	Local $_updateptr
	MakeWstrPtr($_updateptr,$update)
	Local $_optptr
	MakeWstrPtr($_optptr,$options)
	Local $a_result = DllCall($hdll, "WSTR", "UpdateOne", "ptr",$ptr_mongocollection, "ptr", DllStructGetPtr($_searchptr), "ptr", DllStructGetPtr($_updateptr), "ptr", DllStructGetPtr($_optptr));
	ConsoleWrite("UpdateOne: " & $a_result[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
	return $a_result[0]
EndFunc

Func FindOne($ptr_mongocollection, $s_query)
	Local $ptr = DllStructCreate("wchar [" & StringLen($s_query) + 1 & "]") ; +1 for null terminator
	DllStructSetData($ptr, 1, $s_query)
	Local $a_found = DllCall($hdll, "WSTR", "FindOne", "ptr", $ptr_mongocollection, "ptr", DllStructGetPtr($ptr) ) ;the C side prints Hello to ConsoleRead
	ConsoleWrite("FindOne: " & $a_found[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
EndFunc

Func DeleteOne($ptr_mongocollection, $s_query)
	;~returns 1 if 1 document was deleted, otherwise 0
	Local $_searchptr
	MakeWstrPtr($_searchptr,$s_query)
	Local $a_result = DllCall($hdll, "int", "DeleteOne", "ptr",$ptr_mongocollection, "ptr", DllStructGetPtr($_searchptr));
	ConsoleWrite("DeleteOne: " & $a_result[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
	return $a_result[0]
EndFunc

;;
;; HELPERS
;;
Func MakeWstrPtr(ByRef $out,$str_data)
	;~ ByRef Explained: https://www.autoitscript.com/forum/topic/212582-problems-when-returning-dllstructgetptr-from-function/
	Local $_struct = DllStructCreate("wchar [" & StringLen($str_data) + 1 & "]") ; +1 for null terminator
	DllStructSetData($_struct, 1, $str_data)
	$out = $_struct
EndFunc