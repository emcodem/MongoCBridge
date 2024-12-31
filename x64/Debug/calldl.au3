#AutoIt3Wrapper_UseX64=Y
#include <C:\dev\FFAStrans\Processors\JSON.au3>
#include <WinAPIError.au3>
#include <WinAPIMisc.au3>
#include <Array.au3>
;C:\Users\Gam3r1\AppData\Local\Temp\mongod.exe --dbpath C:\temp\filebrdg
Opt("MustDeclareVars", 1)

Global Const $g_sFileDll    = 'C:\dev\MongoCBridge\x64\Debug\MongoCBridge.dll'

Global $s_mongo_url 		= "mongodb://localhost:27017"
Global $s_mongo_database_name 	= "harrysDB"
Global $s_mongo_collection_name 	= "testcollection"

Local $jsonstr = '{"path":"/folder/subfolder/fname.json","content":{"jsoncont":"no"}}'
Local $bigjsonstr = 'C:\temp\ffas_ben\Processors\db\configs\workflows\20230625-1518-1896-1790-0dda9dfc0f34.json'
$bigjsonstr = FileRead($bigjsonstr)

Local $hdll = DllOpen($g_sFileDll)
MsgBox(0,"","")
Local $ptr_mongocollection = CreateCollection($s_mongo_url, $s_mongo_database_name, $s_mongo_collection_name)

; This demo loops through all documents for benchmark
For $i = 1 To 1 Step -1
	Local $nextdoc
	Local $ptr_mongocursor = FindMany($ptr_mongocollection, '{}', '{}')
	Local $doccnt = 0;
	While CursorNext($ptr_mongocursor,$nextdoc)
		$doccnt+=1
		ConsoleWrite("Retrieved Document # " & $doccnt & ", strlen: " & StringLen($nextdoc) & @CRLF)
		ConsoleWrite("Run" & $i)
	WEnd
	CursorDestroy($ptr_mongocursor)
Next


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
	Local $a_result = DllCall($hdll, "int", "DeleteOne", "ptr", $ptr_mongocollection, "ptr", DllStructGetPtr($_searchptr));
	ConsoleWrite("DeleteOne: " & $a_result[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
	return $a_result[0]
EndFunc

Func FindMany($ptr_mongocollection, $s_query, $s_opts)
	;~ returns pointer to mongo cursor, use CursorNext and CursorDestroy for interaction
	Local $_searchptr
	MakeWstrPtr($_searchptr,$s_query)
	Local $_searchopts
	MakeWstrPtr($_searchopts,$s_opts)
	Local $a_result = DllCall($hdll, "ptr", "FindMany", "ptr", $ptr_mongocollection, "ptr", DllStructGetPtr($_searchptr), "ptr", DllStructGetPtr($_searchopts));
	ConsoleWrite("FindMany Cursor Ptr: " & $a_result[0] & " Error: " & _WinAPI_GetLastError() & @CRLF)
	return $a_result[0]
EndFunc

Func CursorNext($ptr_cursor, ByRef $next_doc)
	Local $_resultptr
	;attempt to pass a pointer to pointer to allow the dll to return a pointer to the memory of the json string
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
Func MakeWstrPtr(ByRef $out,$str_data)
	;~ ByRef Explained: https://www.autoitscript.com/forum/topic/212582-problems-when-returning-dllstructgetptr-from-function/
	Local $_struct = DllStructCreate("wchar [" & StringLen($str_data) + 1 & "]") ; +1 for null terminator
	DllStructSetData($_struct, 1, $str_data)
	$out = $_struct
EndFunc
