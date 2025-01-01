#AutoIt3Wrapper_UseX64=Y
;#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#include <C:\dev\FFAStrans\Processors\JSON.au3>
#include <WinAPIError.au3>
#include <WinAPIMisc.au3>
#include <Array.au3>
;C:\Users\Gam3r1\AppData\Local\Temp\mongod.exe --dbpath C:\temp\filebrdg
Opt("MustDeclareVars", 1)
MsgBox(0,"","")
Global Const $g_sFileDll    = 'C:\dev\MongoCBridge\x64\Debug\MongoCBridge.dll'

Global $s_mongo_url 		= "mongodb://localhost:27017"
Global $s_mongo_database_name 	= "harrysDB"
Global $s_mongo_collection_name 	= "testcollection"

Local $small_jsonstr = '{"path":"/folder/subfolder/fname.json","wf_id":"0230625-1518-1896-1790-0dda9dfc0f34"}'
Local $bigjsonstr = 'C:\temp\ffas_ben\Processors\db\configs\workflows\20230625-1518-1896-1790-0dda9dfc0f34.json'
Local $projection_wf_id = '{"projection": {"path": 1,"wf_id": 1},"sort": {"wf_id": 1}}'

$bigjsonstr = FileRead($bigjsonstr)
Local $hdll = DllOpen($g_sFileDll)
Local $ptr_mongocollection = CreateCollection($s_mongo_url, $s_mongo_database_name, $s_mongo_collection_name)

InsertOne($ptr_mongocollection,$small_jsonstr)
FindOne($ptr_mongocollection,"{}",$projection_wf_id)
UpdateOne($ptr_mongocollection,"{}",'{"$set":'&$bigjsonstr&'}','{"upsert":true}')

Exit
; This demo loops through all documents for benchmark
;~ For $i = 1 To 1 Step -1
;~ 	Local $nextdoc
;~ 	Local $ptr_mongocursor = FindMany($ptr_mongocollection, '{}', '{"projection": {"path": 1,"wf_id": 1},"sort": {"wf_id": 1}}')
;~ 	Local $doccnt = 0;
;~ 	While CursorNext($ptr_mongocursor,$nextdoc)
;~ 		$doccnt+=1
;~ 		ConsoleWrite("Retrieved Document # " & $doccnt & ", Content: " & $nextdoc & @CRLF)
;~ 		ConsoleWrite("Run" & $i)
;~ 	WEnd
;~ 	CursorDestroy($ptr_mongocursor)
;~ Next


UpdateOne($ptr_mongocollection, '{"path":"/folder/subfolder/fname.json"}','{"$set":'&$bigjsonstr&'}','{"upsert":true}')
;FindOne($ptr_mongocollection, '{"path":"/folder/subfolder/fname.json"}')
;DeleteOne($ptr_mongocollection, '{"path":"/folder/subfolder/fname.json"}')

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
	Local $_s1,$_s2,$_s3
	Local $constr_ptr  = __MakeWstrPtr($s_mongoconnectionstr,$_s1)
	Local $dbname_ptr  = __MakeWstrPtr($s_mongo_database_name,$_s2)
	Local $colname_ptr = __MakeWstrPtr($s_mongo_collection_name,$s_3)
	Local $a_result = DllCall($hdll, "ptr", "CreateCollection", "ptr", $constr_ptr,"ptr", $dbname_ptr,"ptr", $colname_ptr);
	ConsoleWrite("CreateCollection: " & $a_result[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
	return $a_result[0]
EndFunc

Func InsertOne($ptr_mongocollection,$s_json)
	Local $_s1
	Local $_jsonptr = __MakeWstrPtr($s_json,$_s1)
	Local $a_insertresult = DllCall($hdll, "int:cdecl", "InsertOne", "ptr", $ptr_mongocollection, "ptr",$_jsonptr)
	ConsoleWrite("InsertResult: " & $a_insertresult[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
EndFunc

Func UpdateOne($ptr_mongocollection, $search, $update, $options)
	;~ https://www.mongodb.com/docs/manual/reference/method/db.collection.updateOne/
	;~ commonly used options: {"upsert":true}
	;~ returns json str like { "modifiedCount" : 1, "matchedCount" : 1, "upsertedCount" : 0 }
	Local $_s1,$_s2,$_s3;
	Local $_searchptr 	= __MakeWstrPtr($search, $_s1)
	Local $_updateptr 	= __MakeWstrPtr($update, $_s2)
	Local $_optptr 		= __MakeWstrPtr($options,$_s3)
	Local $a_result 	= DllCall($hdll, "WSTR", "UpdateOne", "ptr", $ptr_mongocollection, "ptr", $_searchptr, "ptr", $_updateptr, "ptr", $_optptr);
	ConsoleWrite("UpdateOne: " & $a_result[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
	return $a_result[0]
EndFunc

Func FindOne($ptr_mongocollection, $s_query, $s_projection)
	Local $_s1,$_s2
	Local $pQuery 		= __MakeWstrPtr($s_query,$_s1)
	Local $pProjection	= __MakeWstrPtr($s_projection,$_s2)
	Local $a_found = DllCall($hdll, "WSTR", "FindOne", "ptr", $ptr_mongocollection, "ptr", $pQuery, "ptr", $pProjection ) ;the C side prints Hello to ConsoleRead
	ConsoleWrite("FindOne: " & $a_found[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
EndFunc

Func DeleteOne($ptr_mongocollection, $s_query)
	;~returns 1 if 1 document was deleted, otherwise 0
	Local $_s1;
	Local $_searchptr 	= __MakeWstrPtr($_searchptr,$_s1)
	Local $a_result 	= DllCall($hdll, "int", "DeleteOne", "ptr", $ptr_mongocollection, "ptr", $_searchptr);
	ConsoleWrite("DeleteOne: " & $a_result[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
	return $a_result[0]
EndFunc

Func FindMany($ptr_mongocollection, $s_query, $s_opts)
	;~ returns pointer to mongo cursor, use CursorNext and CursorDestroy for interaction
	Local $_s1,$_s2
	Local $_searchptr 	= __MakeWstrPtr($_searchptr,$_s1)
	Local $_searchopts 	= __MakeWstrPtr($_searchopts,$_s2)
	Local $a_result = DllCall($hdll, "ptr", "FindMany", "ptr", $ptr_mongocollection, "ptr", $_searchptr, "ptr", $_searchopts);
	ConsoleWrite("FindMany Cursor Ptr: " & $a_result[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
	return $a_result[0]
EndFunc

Func CursorNext($ptr_cursor, ByRef $next_doc)
	Local $_resultptr ; pass a pointer to pointer to allow the dll to return a pointer to the memory of the json string
	Local $a_result = DllCall($hdll, "BOOLEAN", "CursorNext", "ptr", $ptr_cursor, "ptr*", $_resultptr)
	If Not($a_result[0]) Then
		return $a_result[0]
	EndIf
	;idk why $_resultptr is not working, but a_result[2] contains a ptr to our data.
	;https://www.autoitscript.com/forum/topic/196910-get-string-from-pointer-to-memory-solved/
	;we use _WinAPI_StringLenW to determine the length of the pointed string and copy the stuff into autoit variable
	$next_doc = DllStructGetData(DllStructCreate("wchar[" & _WinAPI_StringLenW($a_result[2]) & "]", $a_result[2]), 1)
	;todo: do we need to explicitly free this memory?
	ConsoleWrite("CursorNext: " & $a_result[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
	;ConsoleWrite("CursorNext Result:" & $next_doc & @CRLF)
	return $a_result[0] ; bool
EndFunc

Func CursorDestroy($ptr_cursor)
	DllCall($hdll, "ptr", "CursorDestroy", "ptr", $ptr_cursor)
EndFunc

;;
;; HELPERS
;;
Func __MakeWstrPtr($s_str, ByRef $struct)
    $struct = DllStructCreate("wchar [" & StringLen($s_str) + 1 & "]") ; +1 for null terminator
	DllStructSetData($struct, 1, $s_str)
    return DllStructGetPtr($struct)
EndFunc

