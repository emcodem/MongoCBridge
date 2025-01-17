#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.16.1
 Author:         emcodem

 Script Function:
	Tests and Examples for MongoDB.au3

 Remarks: This must be #included BEFORE the MongoDB.au3,
		  otherwise the string constants '{}' do not work as ByRef Parameter
#ce ----------------------------------------------------------------------------

#include "Mongodb.au3"
#include <File.au3>

Global $iERRORS = 0

_Mongo_Init(@ScriptDir)

_MongoRunTests()

_JsonTests()

UTAssert($iERRORS = 0, "======= ERRORS DETECTED ======")


#Region mongodb.au3 - TESTS

Func _MongoRunTests()
	Local $s_mongo_url 		= "mongodb://localhost:27017"
	Local $s_mongo_database_name 	= "testdb"
	Local $s_mongo_collection_name 	= "testcollection"
	Local $sResult

	;Initialize mongodb driver
	Local $pMongocollection = _Mongo_CreateCollection($s_mongo_url, $s_mongo_database_name, $s_mongo_collection_name)
	If (@error) Then
		ConsoleWrite("TEST ERROR: CreateCollection: " & $sResult)
		Exit 1
	EndIf
	ConsoleWrite("CreateCollection Success" & @CRLF & @CRLF)

	;Set Log file
	Local $sTempFile_1 = _TempFile()
	_Mongo_SetLogFile($sTempFile_1)
	UTAssert(FileGetSize($sTempFile_1) > 0,"Error _Mongo_SetLogFile, file is empty" & $sTempFile_1)
	ConsoleWrite("_Mongo_SetLogFile: " & $sTempFile_1 & @CRLF & @CRLF)

	;Check db status
	$sResult = _Mongo_ClientCommandSimple($pMongocollection,'{"ping": "1"}') 
	UTAssert(@error = 0,"Error ClientCommandSimple ping @error=" & @error)
	UTAssert($sResult = '{ "ok" : { "$numberDouble" : "1.0" } }',"Error ClientCommandSimple ping sResult")
	ConsoleWrite("ping: " & $sResult & @CRLF & @CRLF)

	;Drop test collection just in case (no need to recreate as we have a connection to the collection in pMongocollection)
	$sResult = _Mongo_ClientCommandSimple($pMongocollection, '{"drop": "'&$s_mongo_collection_name&'"}')  
	UTAssert(@error = 0,"Error ClientCommandSimple drop @error=" & @error)
	UTAssert(StringInStr($sResult,"ok"),"Error ClientCommandSimple unexpected return value")
	ConsoleWrite("drop: " & $sResult & @CRLF & @CRLF)

	$sResult = _Mongo_ClientCommandSimple($pMongocollection, '{"create": "'&$s_mongo_collection_name&'"}')  
	UTAssert(@error = 0,"Error ClientCommandSimple create @error=" & @error)
	UTAssert(StringInStr($sResult,"ok"),"Error ClientCommandSimple unexpected return value")
	ConsoleWrite("create: " & $sResult & @CRLF & @CRLF)

	;list indexes
	$sResult = _Mongo_ClientCommandSimple($pMongocollection, '{"listIndexes": "'&$s_mongo_collection_name&'"}' )  
	UTAssert(@error = 0,"Error ClientCommandSimple listIndexes @error=" & @error)
	UTAssert(StringInStr($sResult,"firstBatch"),"Error ClientCommandSimple unexpected return value")
	ConsoleWrite("listIndexes: " & $sResult & @CRLF & @CRLF)

	;insert one document (Perf: 11kps)
	$sResult = _Mongo_InsertOne($pMongocollection, '{"application":"ffastrans","boss":"steinar"}')
	UTAssert(@error = 0,"Error _Mongo_InsertOne document @error=" & @error)
	UTAssert($sResult = True,"Error _Mongo_InsertOne document unexpected return value")
	ConsoleWrite("_Mongo_InsertOne Document: " & $sResult & @CRLF & @CRLF)
	
	;FindOne (Perf: 9kps)
	$sResult = _Mongo_FindOne($pMongocollection,'{"application":"ffastrans"}')
	UTAssert(@error = 0,"Error _Mongo_FindOne @error=" & @error)
	UTAssert(StringInStr($sResult,'ffastrans'),"Error _Mongo_FindOne document unexpected return value")
	ConsoleWrite("_Mongo_InsertOne _Mongo_FindOne: " & $sResult & @CRLF & @CRLF)

	$sResult = _Mongo_InsertOne($pMongocollection, "[0,1,2,3]")
	UTAssert(@error = 0,"Error _Mongo_InsertOne array @error=" & @error)
	UTAssert($sResult = True,"Error _Mongo_InsertOne array unexpected return value")
	ConsoleWrite("_Mongo_InsertOne Array: " & $sResult & @CRLF & @CRLF)
	
	$sResult = _Mongo_UpdateOne($pMongocollection,'{"application":"ffastrans"}','{"$set":{"developers":["emcodem","FranceBB","momocampo"]}}','{"upsert":false}')
	UTAssert(@error = 0,"Error _Mongo_UpdateOne @error=" & @error)
	UTAssert(StringInStr($sResult,'"modifiedCount" : 1'),"Error _Mongo_UpdateOne unexpected return value")
	ConsoleWrite("_Mongo_UpdateOne: " & $sResult & @CRLF & @CRLF)

	$sResult = _Mongo_InsertMany($pMongocollection,'[{"application":"windows"},{"application":"macos"}]')
	UTAssert(@error = 0,"Error _Mongo_InsertMany @error=" & @error)
	UTAssert($sResult = True,"Error _Mongo_InsertMany unexpected return value")
	ConsoleWrite("_Mongo_InsertMany: " & $sResult & @CRLF & @CRLF)

	$sResult = _Mongo_DeleteOne($pMongocollection,'{"application":"macos"}')
	UTAssert(@error = 0,"Error _Mongo_DeleteOne @error=" & @error)
	UTAssert($sResult = True,"Error _Mongo_DeleteOne unexpected return value")
	ConsoleWrite("_Mongo_DeleteOne: " & $sResult & @CRLF & @CRLF)

	$sResult = _Mongo_FindMany($pMongocollection, "{}", "{}")
	UTAssert(@error = 0,"Error _Mongo_FindMany @error=" & @error)
	UTAssert($sResult > 0,"Error _Mongo_FindMany @error=" & @error)
	ConsoleWrite("_Mongo_FindMany Cursor: " & $sResult & @CRLF & @CRLF)

	;Iterate cursor
	Local $aArray = _Mongo_Cursor_To_Array($sResult)
	UTAssert(Ubound($aArray) = 3,"TEST ERROR: _Mongo_Cursor_To_Array, expected: 3, got: " & Ubound ($aArray))
	ConsoleWrite("_Mongo_Cursor_To_Array: " & Ubound($aArray) & @CRLF & @CRLF)

	$sResult = _Mongo_FindMany($pMongocollection, "{}", "{}")
	Local $aArray = _Mongo_Cursor_To_Array($sResult,"",True)
	UTAssert(Ubound($aArray) = 4,"TEST ERROR: _Mongo_Cursor_To_Array, expected: 4, got: " & Ubound ($aArray))
	ConsoleWrite("_Mongo_Cursor_To_Array: " & Ubound($aArray) & @CRLF & @CRLF)
	
EndFunc

#EndRegion mongodb.au3 - TESTS

Func _JsonTests()
	Local $sJ = '{"first":[{"sub":"found"}],"second":{"a":1,"b":2}}'
	Local $val = _Mongo_GetJsonVal($sJ,'first.0.sub')
	UTAssert(($val="found"),"TEST ERROR: _Mongo_Curso_Mongo_GetJsonVal value not found" )
	ConsoleWrite("_Mongo_GetJsonVal: " & $val & @CRLF & @CRLF)
EndFunc


Func UTAssert(Const $bool, Const $msg = "Assert Failure", Const $erl = @ScriptLineNumber)
	If Not $bool Then
		$iERRORS = $iERRORS + 1
		ConsoleWrite("(" & $erl & ") := " & $msg & @LF)
	EndIf
	
	Return $bool
EndFunc   ;==>UTAssert