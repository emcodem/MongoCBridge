#AutoIt3Wrapper_UseX64=Y
Opt("MustDeclareVars", 1)
#include-once
#include <WinAPISys.au3>
#include <Array.au3>

;#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7

; #INDEX# =======================================================================================================================
; Title .........: MongoDB Driver for Autoit
; AutoIt Version : 3.3.16.1
; Language ......: English
; Author(s) .....: emcodem
; Modifiers .....:
; Forum link ....:
; Description ...: Uses MongocBridge.dll which exposes functions of mongoc dlls for easy use from Autoit
; ===============================================================================================================================

;~ _Mongo_Init($sInstallDir = @ScriptDir & "\include\MongoDB_UDF\")
;~ _Mongo_SetLogFile($sFilepath)
;~ _Mongo_CreateCollection($sMongoconnection, $sMongoDatabaseName, $sMongoCollectionName)
;~ _Mongo_InsertOne($pMongocollection, Const ByRef $sJson)
;~ _Mongo_InsertMany($pMongocollection, Const ByRef $sJson)
;~ _Mongo_UpdateOne($pMongocollection, $sQuery, $sUpdate, $sOptions = "{}")
;~ _Mongo_CountDocs($pMongocollection, $sQuery, $sOpts = "{}")
;~ _Mongo_FindOne($pMongocollection, $sQuery, $sProjection = "{}", $sSelector = "")
;~ _Mongo_DeleteOne($pMongocollection, $sQuery)
;~ _Mongo_FindMany($pMongocollection, $sQuery, $sOpts = "{}")
;~ _Mongo_Coll_Aggregate($pMongocollection, $sPipeline, $sOpts = "{}")
;~ _Mongo_CursorNext($pCursor, ByRef $sNext,  $sSelector = "")
;~ _Mongo_Cursor_To_Array($pCursor,$sSelector = "")
;~ _Mongo_CursorDestroy($ptr_cursor)
;~ _Mongo_ClientCommandSimple($pMongocollection, $sCmd, $sDatabase = "")
;~ _Mongo_GetJsonVal($sJson, $sSelector, $sDefault = "")
;~ _Mongo_AppendJsonKV($sJson, $sK, $sV="", $selector="")
;~ _Mongo_JsonAppendSubJson($sJson, $sK, $sV='{"key":"value"}', $selector="" )

; #CONSTANTS# ===================================================================================================================

;autoit docs say we should move these to _constants.au3 but we don't want the user to have to import multiple scripts as it all belongs together
GLOBAL CONST $__BSON_TYPE_EOD = 0x00
GLOBAL CONST $__BSON_TYPE_DOUBLE = 0x01
GLOBAL CONST $__BSON_TYPE_UTF8 = 0x02
GLOBAL CONST $__BSON_TYPE_DOCUMENT = 0x03
GLOBAL CONST $__BSON_TYPE_ARRAY = 0x04
GLOBAL CONST $__BSON_TYPE_BINARY = 0x05
GLOBAL CONST $__BSON_TYPE_UNDEFINED = 0x06
GLOBAL CONST $__BSON_TYPE_OID = 0x07
GLOBAL CONST $__BSON_TYPE_BOOL = 0x08
GLOBAL CONST $__BSON_TYPE_DATE_TIME = 0x09
GLOBAL CONST $__BSON_TYPE_NULL = 0x0A
GLOBAL CONST $__BSON_TYPE_REGEX = 0x0B
GLOBAL CONST $__BSON_TYPE_DBPOINTER = 0x0C
GLOBAL CONST $__BSON_TYPE_CODE = 0x0D
GLOBAL CONST $__BSON_TYPE_SYMBOL = 0x0E
GLOBAL CONST $__BSON_TYPE_CODEWSCOPE = 0x0F
GLOBAL CONST $__BSON_TYPE_INT32 = 0x10
GLOBAL CONST $__BSON_TYPE_TIMESTAMP = 0x11
GLOBAL CONST $__BSON_TYPE_INT64 = 0x12
GLOBAL CONST $__BSON_TYPE_DECIMAL128 = 0x13
GLOBAL CONST $__BSON_TYPE_MAXKEY = 0x7F
GLOBAL CONST $__BSON_TYPE_MINKEY = 0xFF

; ===============================================================================================================================

#Region mongodb.au3 - Functions
; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_Init
; Description ...: Mandatory, Loads the Dlls 
; Syntax.........: _Mongo_Init($sInstallDir)
; Parameters ....: $sFilepath - the Path where MongoDB.au3 along with dependencies Folder is.
; Return values .: None
; Author ........: emcodem (emcodem@ffastrans.com)
; Modified.......:
; Remarks .......:  MongoCbridge.dll links the mongoc dlls, they must be either in the path we use _WinAPI_SetDllDirectory
;					We force it to search them relative to this script
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Mongo_Init($sInstallDir = @ScriptDir & "\include\MongoDB_UDF\")
	Local $sBridgeDllPath = $sInstallDir & "\dependencies\MongoCBridge.dll"
	;Local $sMongoCDllPath = $sInstallDir & "\dependencies\mongoc_driver_1.29.1"
	If Not(FileExists ( $sBridgeDllPath )) Then
		ConsoleWriteError("Not found: " & $sBridgeDllPath)
		Exit(42)
	EndIf
	;_WinAPI_SetDllDirectory ($sMongoCDllPath)
	Global CONST $__hMongo_1_29_1 = DllOpen($sBridgeDllPath)
	;_WinAPI_SetDllDirectory()
	If (@error) Then
		ConsoleWriteError("MongocBridgeDll")
	EndIf
EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_SetLogFile
; Description ...: Set Filename and Path for Mongo Driver logs
; Syntax.........: _Mongo_SetLogFile($sFilepath)
; Parameters ....: $sFilepath - Full File Path, Direcotry must exist
; Return values .: No return values, use _WinAPI_GetLastError() to check for errors
; Author ........: emcodem (emcodem@ffastrans.com)
; Modified.......:
; Remarks .......:  Includes only logs from this driver, not mongodb logs.
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
; Return values .: Bool
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

	Local $aResult 	= DllCall($__hMongo_1_29_1, "BOOLEAN", "InsertOne", "ptr", $pMongocollection, "ptr",$pJson, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_InsertMany
; Description ...: Inserts Array of documents
; Syntax.........: _Mongo_InsertMany($pMongocollection, $sJson)
; Parameters ....: $pMongocollection   		- from CreateCollection
;                  $sJson        			- valid JSON str, starting with "[" it is an array of documents.
;				   $sOptions				- count opts (usually {}) or {"upsert":true}
; Return values .: Boolean, false if failed
; Author ........: emcodem
; Modified.......:
; Remarks .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_InsertMany($pMongocollection, Const ByRef $sJson, $sOptions = "{}")
	Local $t1,$t2
	Local $pJson 	= __Mongo_MakeWstrPtr($sJson,$t1)
	Local $pOpt 	= __Mongo_MakeWstrPtr($sOptions,$t2)
	Local $tErr  	= __Mongo_MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)

	Local $aResult 	= DllCall($__hMongo_1_29_1, "BOOLEAN", "InsertMany", "ptr", $pMongocollection, "ptr",$pJson, "ptr", $pOpt, "ptr", $pErr)
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
Func _Mongo_UpdateOne($pMongocollection, $sQuery, $sUpdate, $sOptions = "{}")
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
; Name...........: _Mongo_CountDocs
; Description ...: Counts docs by query
; Syntax.........: _Mongo_CountDocs($pMongocollection, $sQuery, $sOpts)
; Parameters ....: $pMongocollection   		- from CreateCollection
;                  $sQuery        			- valid JSON str, normal query
;				   $sOpts					- count opts (usually {})
; Return values .: Int64 
; Author ........: emcodem
; Modified.......:
; Remarks .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_CountDocs($pMongocollection, $sQuery, $sOpts = "{}")
	Local $t1,$t2
	Local $pQuery 	= __Mongo_MakeWstrPtr($sQuery,$t1)
	Local $pOpts 	= __Mongo_MakeWstrPtr($sOpts,$t2)
	Local $tErr  	= __Mongo_MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)

	Local $aResult 	= DllCall($__hMongo_1_29_1, "INT64:cdecl", "CountDocuments", "ptr", $pMongocollection, "ptr", $pQuery, "ptr", $pOpts, "ptr", $pErr)
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_FindOne
; Description ...: Find a single document
; Syntax.........: _Mongo_FindOne($pMongocollection, $sQuery, $sProjection = "{}")
; Parameters ....: $pMongocollection	   	- from CreateCollection
;                  $sQuery					- valid JSON str, mongodb query
;                  $sProjection				- valid JSON str, which fields to return
;				   $sSelector				- dot notated accessor for returning subresults, see sSelector@Cursornext
; Return values .: String
; Author ........: emcodem
; Modified.......:
; Remarks .......: Sets @Error code 47 (NoMatchingDocument) if none found
; Link ..........: https://www.mongodb.com/docs/manual/reference/method/db.collection.findOne/
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_FindOne($pMongocollection, $sQuery, $sProjection = "{}", $sSelector = "")
	Local $t1,$t2,$t3
	Local $pQuery 		= __Mongo_MakeWstrPtr($sQuery,$t1)
	Local $pProj		= __Mongo_MakeWstrPtr($sProjection,$t2)
	Local $pSel			= __Mongo_MakeWstrPtr($sSelector,$t3)
	Local $tErr  		= __Mongo_MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($__hMongo_1_29_1, "WSTR", "FindOne", "ptr", $pMongocollection, "ptr", $pQuery, "ptr", $pProj, "ptr", $pSel, "ptr", $pErr )
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_DeleteOne
; Description ...: Find a single document
; Syntax.........: _Mongo_DeleteOne($pMongocollection, $search, $update, $options)
; Parameters ....: $pMongocollection	   	- from CreateCollection
;                  $sQuery					- valid JSON str, mongodb query
;                  $sProjection				- valid JSON str, which fields to return
; Return values .: Bool
; Author ........: emcodem
; Modified.......:
; Remarks .......:
; Link ..........: https://www.mongodb.com/docs/manual/reference/method/db.collection.deleteOne/
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_DeleteOne($pMongocollection, $sQuery)
	Local $t1
	Local $pQuery 		= __Mongo_MakeWstrPtr($sQuery,$t1)
	Local $tErr  		= __Mongo_MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	
	Local $aResult 		= DllCall($__hMongo_1_29_1, "BOOLEAN", "DeleteOne", "ptr", $pMongocollection, "ptr", $pQuery, "ptr", $pErr)
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
; Name...........: _Mongo_Coll_Aggregate
; Description ...: Executes an Aggregation Pipeline
; Syntax.........: _Mongo_Coll_Aggregate($pMongocollection, $sPipeline, $sOpts = "{}")
; Parameters ....: $pMongocollection	   	- from CreateCollection
;                  $sPipelinee				- valid JSON str, mongodb Aggregation Pipeline JSON
;                  $sOpts					- optional, valid JSON str, see docs (example sort, skip)
; Return values .: Pointer to mongoc_cursor_t
; Author ........: emcodem
; Modified.......:
; Remarks .......: Use CursorNext to iterate through the documents, use CursorDestory when you are done to free the memory
; Related .......: CursorNext, CursorDestroy
; Link ..........: https://mongoc.org/libmongoc/current/mongoc_collection_aggregate.html
;				   https://www.mongodb.com/docs/manual/core/aggregation-pipeline/
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_Coll_Aggregate($pMongocollection, $sPipeline, $sOpts = "{}")
	Local $t1,$t2
	Local $pPipeline	= __Mongo_MakeWstrPtr($sPipeline,$t1)
	Local $pOpts 		= __Mongo_MakeWstrPtr($sOpts,$t2)
	Local $tErr  		= __Mongo_MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $aResult 		= DllCall($__hMongo_1_29_1, "ptr", "Collection_Aggregate", "ptr", $pMongocollection, "ptr", $pPipeline, "ptr", $pOpts, "ptr", $pErr);
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_CursorNext
; Description ...: Used to retrieve the next document of the Cursor (mongoc_cursor_t)
; Syntax.........: CursorNext($pCursor, $sQuery, $sNext)
; Parameters ....: $pCursor	   	- from a function that returns a cursor
;                  $sNext		- ByRef variable wich will be populated with the JSON string of next document
;				   $sSelector	- dot notated selector, e.g. key.subkey.0.finalkey, for convenience and save time parsing json
;								- Selector will be applied to the query result, 
;								- it is a replacement for projection in query but can also return non json values
; Return values .: Bool			- true if there there is a next document
; Author ........: emcodem
; Modified.......:
; Remarks .......: Use CursorDestory when you are done to free the memory
;				   Note that the function returns bool to be used in While. The document content is put to $sNext
;			       Sets @error to 47 (no matching documents) if result is empty
; Related .......: _Mongo_CursorNext, _Mongo_CursorDestroy, _Mongo_FindMany
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_CursorNext($pCursor, ByRef $sNext,  $sSelector = "")
	Local $t1
	Local $tErr  		= __Mongo_MakeErrStruct()
	Local $pErr 		= DllStructGetPtr($tErr)
	Local $pResult   	= DllStructGetPtr("")
	Local $pResultlen   = DllStructGetPtr(0)
	Local $pSelector 	= __Mongo_MakeWstrPtr($sSelector,$t1)

	Local $aResult 		= DllCall($__hMongo_1_29_1, "BOOLEAN", "CursorNext", "ptr", $pCursor, "ptr*", $pResult, "UINT64*",$pResultlen,"ptr",  $pSelector, "ptr", $pErr)
	If ($tErr.code <> 0) Then
		ConsoleWrite("Cursor Error " & $tErr.message & @CRLF)
		return SetError($tErr.code, $tErr.code, $tErr.message)
	EndIf
	
	If Not($aResult[0]) Then ;nothing to write to sNext
		return False
	EndIf

	;shame on me that i did not find a better way to return the $aResult from the dll
	;could have just returned wchar_t* like in findOne but i wanted the bool as returnval from C side
	$sNext = DllStructGetData(DllStructCreate("wchar[" & $aResult[3] & "]", $aResult[2]), 1)
	
	return $aResult[0] ; bool
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_Cursor_To_Array
; Description ...: Convenience Function to retrieve all items of cursor and auto close it
; Syntax.........: _Mongo_Cursor_To_Array($pCursor, $sSelector="")
; Parameters ....:  $pCursor (returned by a Function like FindMany)
;   				$sSelector = "" see _Mongo_CursorNext
;					$bAddSize  = True/Fals adds count as first array item, 0 if empty
; Return values .: Array
; Author ........: emcodem
; Modified.......:
; Remarks .......: Releases the Cursor _Mongo_CursorDestroy when done
; 				   No Error handling
; Related .......: _Mongo_CursorNext
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================

Func _Mongo_Cursor_To_Array($pCursor,$sSelector = "",$bAddSize = False)
	Local $sNext
	Local $aArray[1000]
	If $bAddSize = True Then
		_ArrayAdd($aArray,0)
	EndIf
	Local $iCnt = $bAddSize = True ? 1 : 0
	While (_Mongo_CursorNext($pCursor,$sNext,$sSelector))
		If (@error) And ( @error <> 47) Then
			return SetError(@error)
		EndIf
		If (UBound($aArray)-1 < $iCnt) Then
			ReDim $aArray[UBound($aArray) + 1000]
		EndIf
		$aArray[$iCnt] = $sNext
		$iCnt = $iCnt+1
	WEnd
	;ConsoleWrite("_Mongo_Cursor_To_Array " & $pCursor & @LF)
	_ArrayDelete($aArray, $iCnt & "-" & UBound($aArray)-1)
	If $bAddSize = True Then
		$aArray[0] = UBound($aArray) - 1
		If (UBound($aArray) = 1) Then
			$aArray = 0
		EndIf
	EndIf
	_Mongo_CursorDestroy($pCursor)
	return $aArray
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
;				   $bAdmin				- Use "admin" database instead of the collection db
; Return values .: JSON String
; Author ........: emcodem
; Modified.......:
; Remarks .......: Can do the same as all other DB methods and much more
;					Database name is optional, you can e.g. use "admin" to configure your mongo instance.
;					Default Database is the same as the collection uses.
;   				For commands that return multiple docs, only the first one is returned in cursor.firstBatch
; Link ..........: https://mongoc.org/libmongoc/1.29.1/mongoc_client_command_simple.html
;				   https://www.mongodb.com/docs/manual/reference/command/
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_ClientCommandSimple($pMongocollection, $sCmd, $sDatabase = "")
	;https://www.mongodb.com/docs/manual/reference/command/
	Local $t1,$t2,$t3
	Local $pCmd 	= __Mongo_MakeWstrPtr($sCmd,$t1)
	Local $pDb	 	= __Mongo_MakeWstrPtr($sDatabase,$t2)
	Local $tErr  	= __Mongo_MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)
	Local $pDatabase= DllStructGetPtr($sDatabase)
	Local $aResult 	= DllCall($__hMongo_1_29_1, "WSTR", "ClientCommandSimple", "ptr", $pMongocollection, "ptr", $pCmd, "ptr", $pDb,  "ptr", $pErr);
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

#EndRegion mongodb.au3 - Functions

#Region JSON Functions

; #FUNCTION# ====================================================================================================================
; Name...........: _Mongo_GetJsonVal
; Description ...: Convenience function to access values of json str using dot notation key.subkey.0.finalkey
; Syntax.........: _Mongo_GetJsonVal($sJson, "key.subkey", "defaultval")
; Parameters ....: $sJson   		- valid JSON str
;                  $sSelector		- dot notated selector, e.g. key.subkey.0.finalkey
; Return values .: String or JSON string or Array String translated as good as possible from original DB Type
; Author ........: emcodem
; Modified.......:
; Remarks .......: See bson_iter_find_descendant in mongoc docs to learn about mongo dot notation
;					JSON functions only require the dll handle, not the DB funcs
; Link ..........: https://mongoc.org/libbson/current/bson_iter_find_descendant
;				   https://www.mongodb.com/docs/manual/reference/command/
; Example .......: Yes
; ===============================================================================================================================
Func _Mongo_GetJsonVal($sJson, $sSelector, $sDefault = "")
	Local $t1,$t2,$t3
	Local $pJson 	= __Mongo_MakeWstrPtr($sJson,$t1)
	Local $pSelector= __Mongo_MakeWstrPtr($sSelector,$t2)
	Local $pDefault = __Mongo_MakeWstrPtr($sDefault,$t3)
	Local $tErr 	= __Mongo_MakeErrStruct()
	Local $pErr 	= DllStructGetPtr($tErr)
	Local $aResult 	= DllCall($__hMongo_1_29_1, "WSTR", "GetJsonValue","ptr", $pJson, "ptr", $pSelector, "ptr", $pDefault, "ptr", $pErr);
	return $tErr.code <> 0 ? SetError($tErr.code, $tErr.code, $tErr.message) : $aResult[0]
EndFunc

#EndRegion

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

#Region Experimental functions DO NOT USE



Func _overwrite_binary_data_with_dot_notation($pBson, $binaryData, $sSelector="")
	Local $t1,$t2,$t3
	Local $pSel 	= __Mongo_MakeWstrPtr($sSelector, $t1)
	
	$t2 = DllStructCreate("byte[" & BinaryLen($binaryData) & "]")
    DllStructSetData($t2, 1, $binaryData)
	Local $pBinary 	= DllStructGetPtr($t2)
    

	Local $aResult 	= DllCall($__hMongo_1_29_1, "PTR", "_overwrite_binary_data_with_dot_notation","ptr",$pBson,"ptr", $pSel, "ptr", $pBinary, "uint",BinaryLen($binaryData));
	
EndFunc

Func _bson_new_from_json($s)
	Local $t1
	Local $pJson	= __Mongo_MakeWstrPtr($s,$t1)
	Local $aResult 	= DllCall($__hMongo_1_29_1, "PTR", "_bson_new_from_json","ptr", $pJson);
	return $aResult[0]
EndFunc

Func _bson_as_canonical_extended_json($p)
	Local $aResult 	= DllCall($__hMongo_1_29_1, "WSTR", "_bson_as_canonical_extended_json","ptr", $p);
	return $aResult[0]
EndFunc

Func _bson_destroy($p)
	Local $aResult 	= DllCall($__hMongo_1_29_1, "PTR", "_bson_destroy","ptr", $p);
	return $aResult[0]
EndFunc

Func _Mongo_AppendJsonKV($sJson, $sK, $sV, $selector="")
	Local $t1,$t2,$t3,$t4
	Local $pJson	= __Mongo_MakeWstrPtr($sJson,$t1)
	Local $pK 		= __Mongo_MakeWstrPtr($sK,$t2)
	Local $pV 		= __Mongo_MakeWstrPtr($sV,$t3)
	Local $pS 		= __Mongo_MakeWstrPtr($selector,$t4)
	Local $aResult 	= DllCall($__hMongo_1_29_1, "WSTR", "JsonAppendValue","ptr", $pJson, "ptr", $pK, "ptr", $pV, "ptr", $pS);
	return $aResult[0]
EndFunc

Func _Mongo_JsonAppendSubJson($sJson, $sK, $sSubDoc, $selector="" )
	Local $t1,$t2,$t3,$t4
	Local $pJson	= __Mongo_MakeWstrPtr($sJson,$t1)
	Local $pK 		= __Mongo_MakeWstrPtr($sK,$t2)
	Local $pV 		= __Mongo_MakeWstrPtr($sSubDoc,$t3)
	Local $pS 		= __Mongo_MakeWstrPtr($selector,$t4)
	Local $aResult 	= DllCall($__hMongo_1_29_1, "WSTR", "JsonAppendSubJson","ptr", $pJson, "ptr", $pK, "ptr", $pV, "ptr", $pS);
	return $aResult[0]
EndFunc

#EndRegion Experimental functions
