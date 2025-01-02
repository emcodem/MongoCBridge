#AutoIt3Wrapper_UseX64=Y
;#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#include <C:\dev\FFAStrans\Processors\JSON.au3>
#include <WinAPIError.au3>
#include <WinAPIMisc.au3>
#include <Array.au3>
#include <MsgBoxConstants.au3>

;C:\Users\Gam3r1\AppData\Local\Temp\mongod.exe --dbpath C:\temp\filebrdg
Opt("MustDeclareVars", 1)

;db.createUser({user:'ffastrans', pwd: 'ffasTrans', roles:["userAdminAnyDatabase","readWriteAnyDatabase"]})
;Local $small_jsonstr = '{"path":"/folder/subfolder/fname.json","wf_id":"0230625-1518-1896-1790-0dda9dfc0f34"}'

Test()
Exit
#Region mongodb.au3 - TESTS

Func Test()
	Local $g_sFileDll    = 'C:\dev\MongoCBridge\x64\Debug\MongoCBridge.dll'
	Local $hDll = DllOpen($g_sFileDll)
	Local $s_mongo_url 		= "mongodb://localhost:27017"
	Local $s_mongo_database_name 	= "testdb"
	Local $s_mongo_collection_name 	= "testcollection"
	Local $sResult

	;Initialize mongodb driver
	Local $pMongocollection = CreateCollection($hDll, $s_mongo_url, $s_mongo_database_name, $s_mongo_collection_name)
	If (@error) Then
		ConsoleWrite("TEST ERROR: CreateCollection: " & $sResult)
		Exit 1
	EndIf
	ConsoleWrite("CreateCollection Success" & @CRLF)

	;Check db status
	$sResult = ClientCommandSimple($hDll, $pMongocollection,'{"ping": "1"}')  ;{"create": "YEY"}
	If (@error) Then
		ConsoleWrite("TEST ERROR: ClientCommandSimple ping: " & $sResult)
		Exit 1
	EndIf
	ConsoleWrite("ClientCommandSimple ping Success" & @CRLF)

	;Drop test collection just in case
	$sResult = ClientCommandSimple($hDll, $pMongocollection, '{"drop": "'&$s_mongo_collection_name&'"}')  ;{"create": "YEY"}
	If (@error) Then
		ConsoleWrite("TEST ERROR: ClientCommandSimple drop: " & $sResult)
		Exit 1
	EndIf
	ConsoleWrite("ClientCommandSimple drop Success" & @CRLF)

	;Create test collection
	$sResult = ClientCommandSimple($hDll, $pMongocollection, '{"create": "'&$s_mongo_collection_name&'"}')  ;{"create": "YEY"}
	If (@error) Then
		ConsoleWrite("TEST ERROR: ClientCommandSimple create: " & $sResult)
		Exit 1
	EndIf
	ConsoleWrite("ClientCommandSimple create Success" & @CRLF)

	;list indexes
	$sResult = ClientCommandSimple($hDll, $pMongocollection, '{"listIndexes": "'&$s_mongo_collection_name&'"}' )  ;{"create": "YEY"}
	If (@error) Then
		ConsoleWrite("TEST ERROR: ClientCommandSimple listIndexes: " & $sResult)
		Exit 1
	EndIf
	ConsoleWrite("ClientCommandSimple listIndexes Success: " & $sResult & @CRLF)

	$sResult = InsertOne($hDll, $pMongocollection, '{"application":"ffastrans","boss":"steinar"}')
	If (@error) Then
		ConsoleWrite("TEST ERROR: InsertOne: " & $sResult & @CRLF)
		Exit 1
	EndIf
	ConsoleWrite("InsertOne Success" & @CRLF)

	$sResult = UpdateOne($hDll, $pMongocollection,"{}",'{"$set":{"developers":["emcodem","FranceBB","momocampo"]}}','{"upsert":false}')
	If (@error) Then
		ConsoleWrite("TEST ERROR: UpdateOne: " & $sResult & @CRLF)
		Exit 1
	EndIf
	ConsoleWrite("ClientCommandSimple listIndexes Success: " & $sResult & @CRLF)

	$sResult = InsertMany($hDll, $pMongocollection,'[{"application":"windows"},{"application":"macos"}]')
	If (@error) Then
		ConsoleWrite("TEST ERROR: InsertMany: " & $sResult & @CRLF)
		Exit 1
	EndIf
	ConsoleWrite("InsertMany Success: " & $sResult & @CRLF)

	$sResult =  DeleteOne($hDll, $pMongocollection,'{"application":"macos"}')
	If (@error) Then
		ConsoleWrite("TEST ERROR: DeleteOne: " & $sResult & @CRLF)
		Exit 1
	EndIf
	ConsoleWrite("DeleteOne Success: " & $sResult & @CRLF)

	$sResult = FindMany($hDll, $pMongocollection, "{}", "{}")
	If (@error) Then
		ConsoleWrite("TEST ERROR: FindMany: " & $sResult & @CRLF)
		Exit 1
	EndIf
	;Iterate over cursor
	Local $sNext
	While (CursorNext($hDll,$sResult,$sNext))
		ConsoleWrite("FindMany Next: " & $sNext & @CRLF)
	WEnd
	;Release cursor
	CursorDestroy($hDll, $sResult)

EndFunc

#EndRegion mongodb.au3 - TESTS


#Region mongodb.au3 - Functions

; #FUNCTION# ====================================================================================================================
; Name...........: SetLogFile
; Description ...: Set Filename and Path for Mongo Driver logs
; Syntax.........: SetLogFile($sFilepath)
; Parameters ....: $sFilepath - Full File Path, Direcotry must exist
; Return values .: No return values, use _WinAPI_GetLastError() to check for errors
; Author ........: emcodem (emcodem@ffastrans.com)
; Modified.......:
; Remarks .......:  Includes only logs of this driver, not mongodb logs.
;					All Hosts and Collections you open with the same $hDll handle will go to this log.
;					Disables STDERR output of the log lines.
;				   	Each Log is done in a mutex automatically by the mongoc api, it should be thread safe.
;				   	The log file is opened and closed for every line.
;				    For log file rotation, call this function again with new log path/name and delete old logs if required.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func SetLogFile($hDll, $sFilepath)
	Local $t1
	Local $_path	 = __MakeWstrPtr($sFilepath,$t1)
	DllCall($hdll, "NONE", "SetLogFile", "ptr", $_path)
	ConsoleWrite("SetLogFile Error: " & _WinAPI_GetLastError() & @CRLF)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: CreateCollection
; Description ...: Initialize Structure, needed for all interactions with mongodb
; Syntax.........: CreateCollection("mongodb://user@passwd:localhost:27017","mydatabase","mycollection")
; Parameters ....: 	$s_mongoconnectionstr 		- a valid mongodb connection url, optionally can contain username and pwd
;					$s_mongo_database_name		- mongo db name
;					$s_mongo_collection_name	- mongo collection name
; Return values .: Pointer to _mongoc_collection_t from the mongo C API
; Author ........: emcodem (emcodem@ffastrans.com)
; Modified.......:
; Remarks .......: You must do this before calling any function that interacts with mongod.
;				   If you specify a non existing collection, it will be created.
;				   As long as you want to interact with the same database and collection, you can store this the returned value globally and re-use forever.
;				   The database does not have to be online for this to succeed, only the connection url must be valid.
;				   You do not need to repeat calling CreateCollection, even if the database goes offline and returns.
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func CreateCollection($hDll, $sMongoconnection, $sMongoDatabaseName, $sMongoCollectionName)
	;~ if DB is offline, we still get a valid collection that works once the db comes online
	Local $t1,$t2,$t3
	Local $pconn	= __MakeWstrPtr($sMongoconnection,	$t1)
	Local $pdb		= __MakeWstrPtr($sMongoDatabaseName,$t2)
	Local $pcol		= __MakeWstrPtr($sMongoCollectionName,$t3)
	Local $tErr  	= __MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)

	Local $aResult 	= DllCall($hDll, "ptr", "CreateCollection", "ptr", $pconn,"ptr", $pdb,"ptr", $pcol, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: InsertOne
; Description ...: Insert a single json document into collection
; Syntax.........: InsertOne($pMongocollection, $sJson)
; Parameters ....: $pMongocollection   		- from CreateCollection
;                  $sJson        			- valid JSON str, the document to be inserted
; Return values .: Mongodb Error Code, 0 if success
; Author ........: emcodem
; Modified.......:
; Remarks .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func InsertOne($hDll, $pMongocollection, Const ByRef $sJson)
	Local $t1
	Local $pJson 	= __MakeWstrPtr($sJson,$t1)
	Local $tErr  	= __MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)

	Local $aResult 	= DllCall($hDll, "int:cdecl", "InsertOne", "ptr", $pMongocollection, "ptr",$pJson, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: InsertMany
; Description ...: Inserts Array of documents
; Syntax.........: InsertMany($pMongocollection, $sJson)
; Parameters ....: $pMongocollection   		- from CreateCollection
;                  $sJson        			- valid JSON str, starting with "[" it is an array of documents.
; Return values .: Boolean, false if failed
; Author ........: emcodem
; Modified.......:
; Remarks .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func InsertMany($hDll, $pMongocollection, Const ByRef $sJson)
	Local $t1
	Local $pJson 	= __MakeWstrPtr($sJson,$t1)
	Local $tErr  	= __MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)

	Local $aResult 	= DllCall($hDll, "BOOLEAN", "InsertMany", "ptr", $pMongocollection, "ptr",$pJson, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: UpdateOne
; Description ...: Update a single Document in collection
; Syntax.........: UpdateOne($pMongocollection, $search, $update, $options)
; Parameters ....: $pMongocollection	   	- from CreateCollection
;                  $s_search				- valid JSON str, mongodb query, used to select the document to be updated
;                  $s_update				- valid JSON str, full document or only parts you want to insert/update
;				   $s_options				- valid JSON str, commonly used options: {"upsert":true}, {}
; Return values .: Mongodb Error Code, 0 if success
; Author ........: emcodem
; Modified.......:
; Remarks .......:
; Link ..........: https://www.mongodb.com/docs/manual/reference/method/db.collection.updateOne/
; Example .......: Yes
; ===============================================================================================================================
Func UpdateOne($hDll, $pMongocollection, $sQuery, $sUpdate, $sOptions)
	;~ https://www.mongodb.com/docs/manual/reference/method/db.collection.updateOne/
	;~ commonly used options: {"upsert":true}
	;~ returns json str like { "modifiedCount" : 1, "matchedCount" : 1, "upsertedCount" : 0 }
	Local $t1,$t2,$t3;
	Local $pSearch 		= __MakeWstrPtr($sQuery, 	$t1)
	Local $pUpdate 		= __MakeWstrPtr($sUpdate, 	$t2)
	Local $pOpt 		= __MakeWstrPtr($sOptions,	$t3)
	Local $tErr  		= __MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($hDll, "WSTR", "UpdateOne", "ptr", $pMongocollection, "ptr", $pSearch, "ptr", $pUpdate, "ptr", $pOpt, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: FindOne
; Description ...: Find a single document
; Syntax.........: FindOne($pMongocollection, $search, $update, $options)
; Parameters ....: $pMongocollection	   	- from CreateCollection
;                  $sQuery					- valid JSON str, mongodb query
;                  $sProjection				- valid JSON str, which fields to return
; Return values .: JSON String, the document found or {}
; Author ........: emcodem
; Modified.......:
; Remarks .......:
; Link ..........: https://www.mongodb.com/docs/manual/reference/method/db.collection.findOne/
; Example .......: Yes
; ===============================================================================================================================
Func FindOne($hDll, $pMongocollection, $sQuery, $sProjection = "{}")
	Local $t1,$t2
	Local $pQuery 		= __MakeWstrPtr($sQuery,$t1)
	Local $pProjection	= __MakeWstrPtr($sProjection,$t2)
	Local $tErr  		= __MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($hDll, "WSTR", "FindOne", "ptr", $pMongocollection, "ptr", $pQuery, "ptr", $pProjection, "ptr", $pErr ) ;the C side prints Hello to ConsoleRead
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: FindMany
; Description ...: Find multiple documents
; Syntax.........: FindMany($pMongocollection, $sQuery, $sOpts)
; Parameters ....: $pMongocollection	   	- from CreateCollection
;                  $sQuery					- valid JSON str, mongodb query
;                  $sOpts					- optional, valid JSON str, see docs (example sort, skip)
; Return values .: Pointer to mongoc_cursor_t
; Author ........: emcodem
; Modified.......:
; Remarks .......: Use CursorNext to iterate through the documents, use CursorDestory when you are done to free the memory
; Related .......: CursorNext, CursorDestroy
; Link ..........: https://www.mongodb.com/docs/manual/reference/method/db.collection.find/
; Example .......: Yes
; ===============================================================================================================================
Func FindMany($hDll, $pMongocollection, $sQuery, $sOpts = "{}")
	;~ returns pointer to mongo cursor, use CursorNext and CursorDestroy for interaction
	Local $t1,$t2
	Local $pQuery	 	= __MakeWstrPtr($sQuery,$t1)
	Local $pOpts 		= __MakeWstrPtr($sOpts,$t2)
	Local $tErr  		= __MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($hDll, "ptr", "FindMany", "ptr", $pMongocollection, "ptr", $pQuery, "ptr", $pOpts, "ptr", $pErr);
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: DeleteOne
; Description ...: Find a single document
; Syntax.........: DeleteOne($pMongocollection, $search, $update, $options)
; Parameters ....: $pMongocollection	   	- from CreateCollection
;                  $sQuery					- valid JSON str, mongodb query
;                  $sProjection				- valid JSON str, which fields to return
; Return values .: JSON String, the document found or {}
; Author ........: emcodem
; Modified.......:
; Remarks .......:
; Link ..........: https://www.mongodb.com/docs/manual/reference/method/db.collection.deleteOne/
; Example .......: Yes
; ===============================================================================================================================
Func DeleteOne($hDll, $pMongocollection, $sQuery)
	;~returns 1 if 1 document was deleted, otherwise 0
	Local $t1;
	Local $pQuery 		= __MakeWstrPtr($sQuery,$t1)
	Local $tErr  		= __MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($hDll, "int", "DeleteOne", "ptr", $pMongocollection, "ptr", $pQuery, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: CursorNext
; Description ...: Used to retrieve the next document of the Cursor (mongoc_cursor_t)
; Syntax.........: CursorNext($pCursor, $sQuery, $sNext)
; Parameters ....: $pCursor	   	- from a function that returns a cursor
;                  $sNext		- ByRef variable wich will be populated with the JSON string of next document
; Return values .: Bool			- true if there there is a next document
; Author ........: emcodem
; Modified.......:
; Remarks .......: Use CursorDestory when you are done to free the memory
;				   Note that the function returns bool to be used in While. The document content is put to $sNext
; Related .......: CursorNext
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func CursorNext($hDll, $pCursor, ByRef $sNext)
	Local $pResult 		; pass a pointer to pointer to allow the dll to return a pointer to the memory of the json string
	Local $tErr  		= __MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($hDll, "BOOLEAN", "CursorNext", "ptr", $pCursor, "ptr*", $pResult, "ptr", $pErr)
	If ($tErr.code <> 0) Then
		return SetError($tErr.code, $tErr.code, $tErr.message)
	EndIf
	If Not($aResult[0]) Then ;nothing to return
		return $aResult[0]
	EndIf
	;idk why $_resultptr is not working, but aResult[2] contains a ptr to our data.
	;https://www.autoitscript.com/forum/topic/196910-get-string-from-pointer-to-memory-solved/
	;we use _WinAPI_StringLenW to determine the length of the pointed string and copy the stuff into autoit variable
	$sNext = DllStructGetData(DllStructCreate("wchar[" & _WinAPI_StringLenW($aResult[2]) & "]", $aResult[2]), 1)
	;todo: do we need to explicitly free this memory?

	return $aResult[0] ; bool
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: CursorDestroy
; Description ...: MANDATORY for any Cursor. Used to free the memory of a Cursor (mongoc_cursor_t)
; Syntax.........: CursorDestroy($pCursor, $sQuery, $next_doc)
; Parameters ....: $pCursor	   	- from CreateCollection
; Return values .: None
; Author ........: emcodem
; Modified.......:
; Remarks .......: Call this when you finished iterating your cursor.
; Related .......: CursorDestroy
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func CursorDestroy($hDll, $ptr_cursor)
	DllCall($hDll, "ptr", "CursorDestroy", "ptr", $ptr_cursor)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: ClientCommandSimple
; Description ...: mongoc_client_command_simple
; Syntax.........: ClientCommandSimple($pMongocollection, $sCmd)
; Parameters ....: $pMongocollection   	- from CreateCollection
;                  $sCmd				- valid JSON str, mongodb query, used to select the document to be updated
; Return values .: JSON String
; Author ........: emcodem
; Modified.......:
; Remarks .......: Can do the same as all other methods and much more.
;					Feature set compareable to mongos shell
;   				For commands that return multiple docs, only the first one is returned in cursor.firstBatch
; Link ..........: https://mongoc.org/libmongoc/1.29.1/mongoc_client_command_simple.html
;				   https://www.mongodb.com/docs/manual/reference/command/
; Example .......: Yes
; ===============================================================================================================================
Func ClientCommandSimple($hDll, $pMongocollection, ByRef $sCmd)
	;https://www.mongodb.com/docs/manual/reference/command/
	Local $t1
	Local $pCmd 	= __MakeWstrPtr($sCmd,$t1)
	Local $tErr  	= __MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)

	Local $aResult 	= DllCall($hDll, "WSTR", "ClientCommandSimple", "ptr", $pMongocollection, "ptr", $pCmd, "ptr", $pErr);
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

#EndRegion mongodb.au3 - Functions

#Region mongodb.au3 - Functions - MISC
; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __MakeWstrPtr
; Description ...: string to wchar_t pointer (keeps utf-16 encoding)
; Syntax.........: __MakeWstrPtr($sStr,$t1)
; Parameters ....: $sStr   	- User defined string
;                  $tStruct		- Empty variable, see Remarks
; Return values .: Pointer to $sStr for use in DllCall
; Author ........: emcodem
; Remarks .......: Caller must guarantee $tStruct is not released until the data of returned pointer is obsolete
; Link ..........: https://www.autoitscript.com/forum/topic/212582-problems-when-returning-dllstructgetptr-from-function/
; Example .......: No
; ===============================================================================================================================
Func __MakeWstrPtr($sStr, ByRef $tStruct)
    $tStruct 	= DllStructCreate("wchar [" & StringLen($sStr) + 1 & "]") ; +1 for null terminator
	DllStructSetData($tStruct, 1, $sStr)
    return DllStructGetPtr($tStruct)
EndFunc

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __MakeErrStruct
; Description ...: initialize error struct
; Syntax.........: __MakeErrStruct($sStr,$t1)
; Return values .: Error Struct to be used in CallDll
; Author ........: emcodem
; Example .......: No
; ===============================================================================================================================
Func __MakeErrStruct()
	Local $tErrStruct = DllStructCreate("struct;int code;wchar message[1024];endstruct")
	DllStructSetData($tErrStruct, "code", 0)
	DllStructSetData($tErrStruct, "message", "")
	return $tErrStruct
EndFunc
#EndRegion mongodb.au3 - Functions - MISC
