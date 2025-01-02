#AutoIt3Wrapper_UseX64=Y
Opt("MustDeclareVars", 1)
#include-once
#include <WinAPIMisc.au3>
#include <WinAPISys.au3>

;#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7

; #INDEX# =======================================================================================================================
; Title .........: MongoDB Driver for Autoit
; AutoIt Version : 3.3.10.2
; Language ......: English
; Author(s) .....: emcodem
; Modifiers .....:
; Forum link ....:
; Description ...: An example UDF that does very little.
; ===============================================================================================================================




; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_Init
; Description ...: Set Filename and Path for Mongo Driver logs
; Syntax.........: _Mongo_Init($sInstallDir)
; Parameters ....: $sFilepath - Full File Path, Direcotry must exist
; Return values .: No return values, use _WinAPI_GetLastError() to check for errors
; Author ........: emcodem (emcodem@ffastrans.com)
; Modified.......:
; Remarks .......:
;
;					MongoCbridge.dll resolves mongoc dlls in path and executeable folder
;					We force it to search them relative to this script
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Mongo_Init($sInstallDir = @ScriptDir & "\include\MongoDB_UDF\")
	Local $sBridgeDllPath = $sInstallDir & "\dependencies\MongoCBridge.dll"
	Local $sMongoCDllPath = $sInstallDir & "\dependencies\mongoc_driver_1.29.1"
	If Not(FileExists ( $sBridgeDllPath )) Then
		ConsoleWriteError("Not found: " & $sBridgeDllPath)
		Exit(42)
	EndIf
	_WinAPI_SetDllDirectory ($sMongoCDllPath)
	Global CONST $__hMongo_1_29_1 = DllOpen($sBridgeDllPath)
	_WinAPI_SetDllDirectory()
	If (@error) Then
		ConsoleWriteError("MongocBridgeDll")
	EndIf
EndFunc

#Region mongodb.au3 - Functions

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_SetLogFile
; Description ...: Set Filename and Path for Mongo Driver logs
; Syntax.........: _Mongo_SetLogFile($sFilepath)
; Parameters ....: $sFilepath - Full File Path, Direcotry must exist
; Return values .: No return values, use _WinAPI_GetLastError() to check for errors
; Author ........: emcodem (emcodem@ffastrans.com)
; Modified.......:
; Remarks .......:  Includes only logs of this driver, not mongodb logs.
;					All Hosts and Collections you open with the same $__hMongo_1_29_1 handle will go to this log.
;					Disables STDERR output of the log lines.
;				   	Each Log is done in a mutex automatically by the mongoc api, it should be thread safe.
;				   	The log file is opened and closed for every line.
;				    For log file rotation, call this function again with new log path/name and delete old logs if required.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Mongo_SetLogFile($sFilepath)
	Local $t1
	Local $pPath	= __Mongo_MakeWstrPtr($sFilepath,$t1)
	Local $tErr  	= __Mongo_MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)
	ConsoleWrite($__hMongo_1_29_1)
	DllCall($__hMongo_1_29_1, "NONE", "SetLogFile", "ptr", $pPath)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : ""
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_CreateCollection
; Description ...: Initialize Structure, needed for all interactions with mongodb
; Syntax.........: _Mongo_CreateCollection("mongodb://user@passwd:localhost:27017","mydatabase","mycollection")
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
Func _Mongo_CreateCollection($sMongoconnection, $sMongoDatabaseName, $sMongoCollectionName)
	;~ if DB is offline, we still get a valid collection that works once the db comes online
	Local $t1,$t2,$t3
	Local $pconn	= __Mongo_MakeWstrPtr($sMongoconnection,	$t1)
	Local $pdb		= __Mongo_MakeWstrPtr($sMongoDatabaseName,$t2)
	Local $pcol		= __Mongo_MakeWstrPtr($sMongoCollectionName,$t3)
	Local $tErr  	= __Mongo_MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)

	Local $aResult 	= DllCall($__hMongo_1_29_1, "ptr", "CreateCollection", "ptr", $pconn,"ptr", $pdb,"ptr", $pcol, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_InsertOne
; Description ...: Insert a single json document into collection
; Syntax.........: _Mongo_InsertOne($pMongocollection, $sJson)
; Parameters ....: $pMongocollection   		- from CreateCollection
;                  $sJson        			- valid JSON str, the document to be inserted
; Return values .: Mongodb Error Code, 0 if success
; Author ........: emcodem
; Modified.......:
; Remarks .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_InsertOne($pMongocollection, Const ByRef $sJson)
	Local $t1
	Local $pJson 	= __Mongo_MakeWstrPtr($sJson,$t1)
	Local $tErr  	= __Mongo_MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)

	Local $aResult 	= DllCall($__hMongo_1_29_1, "int:cdecl", "InsertOne", "ptr", $pMongocollection, "ptr",$pJson, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_InsertMany
; Description ...: Inserts Array of documents
; Syntax.........: _Mongo_InsertMany($pMongocollection, $sJson)
; Parameters ....: $pMongocollection   		- from CreateCollection
;                  $sJson        			- valid JSON str, starting with "[" it is an array of documents.
; Return values .: Boolean, false if failed
; Author ........: emcodem
; Modified.......:
; Remarks .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_InsertMany($pMongocollection, Const ByRef $sJson)
	Local $t1
	Local $pJson 	= __Mongo_MakeWstrPtr($sJson,$t1)
	Local $tErr  	= __Mongo_MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)

	Local $aResult 	= DllCall($__hMongo_1_29_1, "BOOLEAN", "InsertMany", "ptr", $pMongocollection, "ptr",$pJson, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_UpdateOne
; Description ...: Update a single Document in collection
; Syntax.........: _Mongo_UpdateOne($pMongocollection, $search, $update, $options)
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
Func _Mongo_UpdateOne($pMongocollection, $sQuery, $sUpdate, $sOptions)
	;~ https://www.mongodb.com/docs/manual/reference/method/db.collection.updateOne/
	;~ commonly used options: {"upsert":true}
	;~ returns json str like { "modifiedCount" : 1, "matchedCount" : 1, "upsertedCount" : 0 }
	Local $t1,$t2,$t3;
	Local $pSearch 		= __Mongo_MakeWstrPtr($sQuery, 	$t1)
	Local $pUpdate 		= __Mongo_MakeWstrPtr($sUpdate, 	$t2)
	Local $pOpt 		= __Mongo_MakeWstrPtr($sOptions,	$t3)
	Local $tErr  		= __Mongo_MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($__hMongo_1_29_1, "WSTR", "UpdateOne", "ptr", $pMongocollection, "ptr", $pSearch, "ptr", $pUpdate, "ptr", $pOpt, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_FindOne
; Description ...: Find a single document
; Syntax.........: _Mongo_FindOne($pMongocollection, $search, $update, $options)
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
Func _Mongo_FindOne($pMongocollection, $sQuery, $sProjection = "{}")
	Local $t1,$t2
	Local $pQuery 		= __Mongo_MakeWstrPtr($sQuery,$t1)
	Local $pProjection	= __Mongo_MakeWstrPtr($sProjection,$t2)
	Local $tErr  		= __Mongo_MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($__hMongo_1_29_1, "WSTR", "FindOne", "ptr", $pMongocollection, "ptr", $pQuery, "ptr", $pProjection, "ptr", $pErr ) ;the C side prints Hello to ConsoleRead
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_FindMany
; Description ...: Find multiple documents
; Syntax.........: _Mongo_FindMany($pMongocollection, $sQuery, $sOpts)
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
Func _Mongo_FindMany($pMongocollection, $sQuery, $sOpts = "{}")
	Local $t1,$t2
	Local $pQuery	 	= __Mongo_MakeWstrPtr($sQuery,$t1)
	Local $pOpts 		= __Mongo_MakeWstrPtr($sOpts,$t2)
	Local $tErr  		= __Mongo_MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($__hMongo_1_29_1, "ptr", "FindMany", "ptr", $pMongocollection, "ptr", $pQuery, "ptr", $pOpts, "ptr", $pErr);
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_DeleteOne
; Description ...: Find a single document
; Syntax.........: _Mongo_DeleteOne($pMongocollection, $search, $update, $options)
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
Func _Mongo_DeleteOne($pMongocollection, $sQuery)
	;~returns 1 if 1 document was deleted, otherwise 0
	Local $t1;
	Local $pQuery 		= __Mongo_MakeWstrPtr($sQuery,$t1)
	Local $tErr  		= __Mongo_MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($__hMongo_1_29_1, "int", "DeleteOne", "ptr", $pMongocollection, "ptr", $pQuery, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_CursorNext
; Description ...: Used to retrieve the next document of the Cursor (mongoc_cursor_t)
; Syntax.........: CursorNext($pCursor, $sQuery, $sNext)
; Parameters ....: $pCursor	   	- from a function that returns a cursor
;                  $sNext		- ByRef variable wich will be populated with the JSON string of next document
; Return values .: Bool			- true if there there is a next document
; Author ........: emcodem
; Modified.......:
; Remarks .......: Use CursorDestory when you are done to free the memory
;				   Note that the function returns bool to be used in While. The document content is put to $sNext
; Related .......: _Mongo_CursorNext, _Mongo_CursorDestroy, _Mongo_FindMany
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_CursorNext($pCursor, ByRef $sNext)
	Local $tResult = ""		; pass a pointer to pointer to allow the dll to return a pointer to the memory of the json string
	Local $pResult = DllStructGetPtr($tResult)
	Local $tErr  		= __Mongo_MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($__hMongo_1_29_1, "BOOLEAN", "CursorNext", "ptr", $pCursor, "ptr*", $pResult, "ptr", $pErr)
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
; Name...........: _Mongo_CursorDestroy
; Description ...: MANDATORY for any Cursor. Used to free the memory of a Cursor (mongoc_cursor_t)
; Syntax.........: _Mongo_CursorDestroy($pCursor, $sQuery, $next_doc)
; Parameters ....: $pCursor	   	- from CreateCollection
; Return values .: None
; Author ........: emcodem
; Modified.......:
; Remarks .......: Call this when you finished iterating your cursor.
; Related .......:
; Link ..........: _Mongo_CursorNext, _Mongo_CursorDestroy, _Mongo_FindMany
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_CursorDestroy($ptr_cursor)
	DllCall($__hMongo_1_29_1, "ptr", "CursorDestroy", "ptr", $ptr_cursor)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_ClientCommandSimple
; Description ...: mongoc_client_command_simple
; Syntax.........: _Mongo_ClientCommandSimple($pMongocollection, $sCmd)
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
Func _Mongo_ClientCommandSimple($pMongocollection, ByRef $sCmd)
	;https://www.mongodb.com/docs/manual/reference/command/
	Local $t1
	Local $pCmd 	= __Mongo_MakeWstrPtr($sCmd,$t1)
	Local $tErr  	= __Mongo_MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)

	Local $aResult 	= DllCall($__hMongo_1_29_1, "WSTR", "ClientCommandSimple", "ptr", $pMongocollection, "ptr", $pCmd, "ptr", $pErr);
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

#EndRegion mongodb.au3 - Functions

#Region mongodb.au3 - Functions - MISC
; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __Mongo_MakeWstrPtr
; Description ...: string to wchar_t pointer (keeps utf-16 encoding)
; Syntax.........: __Mongo_MakeWstrPtr($sStr,$t1)
; Parameters ....: $sStr   	- User defined string
;                  $tStruct		- Empty variable, see Remarks
; Return values .: Pointer to $sStr for use in DllCall
; Author ........: emcodem
; Remarks .......: Caller must guarantee $tStruct is not released until the data of returned pointer is obsolete
; Link ..........: https://www.autoitscript.com/forum/topic/212582-problems-when-returning-dllstructgetptr-from-function/
; Example .......: No
; ===============================================================================================================================
Func __Mongo_MakeWstrPtr($sStr, ByRef $tStruct)
    $tStruct 	= DllStructCreate("wchar [" & StringLen($sStr) + 1 & "]") ; +1 for null terminator
	DllStructSetData($tStruct, 1, $sStr)
    return DllStructGetPtr($tStruct)
EndFunc

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __Mongo_MakeErrStruct
; Description ...: initialize error struct
; Syntax.........: __Mongo_MakeErrStruct($sStr,$t1)
; Return values .: Error Struct to be used in CallDll
; Author ........: emcodem
; Example .......: No
; ===============================================================================================================================
Func __Mongo_MakeErrStruct()
	Local $tErrStruct = DllStructCreate("struct;int code;wchar message[1024];endstruct")
	DllStructSetData($tErrStruct, "code", 0)
	DllStructSetData($tErrStruct, "message", "")
	return $tErrStruct
EndFunc
#EndRegion mongodb.au3 - Functions - MISC
