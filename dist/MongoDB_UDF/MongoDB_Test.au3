#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.16.1
 Author:         emcodem

 Script Function:
	Tests and Examples for MongoDB.au3

 Remarks: This must be #included BEFORE the MongoDB.au3,
		  otherwise the string constants '{}' do not work as ByRef Parameter
#ce ----------------------------------------------------------------------------

#include "Mongodb.au3"

#Region mongodb.au3 - TESTS
Func _MongoRunJsonTests()
	Local $makeIndexcmd = '{"createIndexes": "configs","indexes": [{"key":{ "name": 1 },"name": "MYINDEXNAME","unique": true},{"key":true}]}'
	;retrieve Array
	Local $ret = _Mongo_GetJsonVal($makeIndexcmd,"indexes","")
	;iterate Array
	Local $iDx = -1
	Local $array_ret
	Local $aResults[2]
	While $array_ret <> "_EOF_"
		$iDx += 1
		$array_ret = _Mongo_GetJsonVal($ret,$iDx,"_EOF_")
		;_ArrayPush($aResults, $array_ret)
		ConsoleWrite("TEST Array Ret: " & $array_ret & @CRLF)
	Wend
	
	If ($iDx <> 2) Then
		ConsoleWrite("TEST ERROR: _Mongo_GetJsonVal: Array Error, expected 2, got "&$iDx)
		Exit 1
	EndIf
EndFunc

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
	ConsoleWrite("CreateCollection Success" & @CRLF)

	;Check db status
	$sResult = _Mongo_ClientCommandSimple($pMongocollection,'{"ping": "1"}')  ;{"create": "YEY"}
	If (@error) Then
		ConsoleWrite("TEST ERROR: ClientCommandSimple ping: " & $sResult)
		Exit 1
	EndIf
	ConsoleWrite("ClientCommandSimple ping Success" & @CRLF)

	;Drop test collection just in case
	$sResult = _Mongo_ClientCommandSimple($pMongocollection, '{"drop": "'&$s_mongo_collection_name&'"}')  ;{"create": "YEY"}
	If (@error) Then
		ConsoleWrite("TEST ERROR: ClientCommandSimple drop: " & $sResult)
		Exit 1
	EndIf
	ConsoleWrite("ClientCommandSimple drop Success" & @CRLF)

	;Create test collection
	$sResult = _Mongo_ClientCommandSimple($pMongocollection, '{"create": "'&$s_mongo_collection_name&'"}')  ;{"create": "YEY"}
	If (@error) Then
		ConsoleWrite("TEST ERROR: ClientCommandSimple create: " & $sResult)
		Exit 1
	EndIf
	ConsoleWrite("ClientCommandSimple create Success" & @CRLF)

	;list indexes
	$sResult = _Mongo_ClientCommandSimple($pMongocollection, '{"listIndexes": "'&$s_mongo_collection_name&'"}' )  ;{"create": "YEY"}
	If (@error) Then
		ConsoleWrite("TEST ERROR: ClientCommandSimple listIndexes: " & $sResult)
		Exit 1
	EndIf
	ConsoleWrite("ClientCommandSimple listIndexes Success" & @CRLF)

	$sResult = _Mongo_InsertOne($pMongocollection, '{"application":"ffastrans","boss":"steinar"}')
	If (@error) Then
		ConsoleWrite("TEST ERROR: InsertOne: " & $sResult & @CRLF)
		Exit 1
	EndIf
	ConsoleWrite("InsertOne Success" & @CRLF)

	$sResult = _Mongo_InsertOne($pMongocollection, '[1,2]')
	If (@error) Then
		ConsoleWrite("TEST ERROR: InsertOne Array: " & $sResult & @CRLF)
		Exit 1
	EndIf
	ConsoleWrite("InsertOne Array Success" & @CRLF)


	$sResult = _Mongo_UpdateOne($pMongocollection,"{}",'{"$set":{"developers":["emcodem","FranceBB","momocampo"]}}','{"upsert":false}')
	If (@error) Then
		ConsoleWrite("TEST ERROR: UpdateOne: " & $sResult & @CRLF)
		Exit 1
	EndIf
	ConsoleWrite("UpdateOne Success " & @CRLF)

	$sResult = _Mongo_InsertMany($pMongocollection,'[{"application":"windows"},{"application":"macos"}]')
	If (@error) Then
		ConsoleWrite("TEST ERROR: InsertMany: " & $sResult & @CRLF)
		Exit 1
	EndIf
	ConsoleWrite("InsertMany Success" & @CRLF)

	$sResult = _Mongo_DeleteOne($pMongocollection,'{"application":"macos"}')
	If (@error) Then
		ConsoleWrite("TEST ERROR: DeleteOne: " & $sResult & @CRLF)
		Exit 1
	EndIf
	ConsoleWrite("DeleteOne Success" & @CRLF)

	$sResult = _Mongo_FindMany($pMongocollection, "{}", "{}")
	If (@error) Then
		ConsoleWrite("TEST ERROR: FindMany: " & $sResult & @CRLF)
		Exit 1
	EndIf
	;Iterate over cursor
	Local $aArray = _Mongo_Cursor_To_Array($sResult)
	If (Ubound($aArray) <> 3) Then
		ConsoleWrite("TEST ERROR: _Mongo_Cursor_To_Array, expected: 3, got: " & Ubound ($aArray) &  @CRLF)
		Exit 1
	EndIf

EndFunc

#EndRegion mongodb.au3 - TESTS

