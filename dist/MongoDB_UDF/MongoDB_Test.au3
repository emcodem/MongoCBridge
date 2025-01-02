#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.16.1
 Author:         emcodem

 Script Function:
	Tests and Examples for MongoDB.au3

#ce ----------------------------------------------------------------------------


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
	ConsoleWrite("ClientCommandSimple listIndexes Success: " & $sResult & @CRLF)

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
	ConsoleWrite("ClientCommandSimple listIndexes Success: " & $sResult & @CRLF)

	$sResult = _Mongo_InsertMany($pMongocollection,'[{"application":"windows"},{"application":"macos"}]')
	If (@error) Then
		ConsoleWrite("TEST ERROR: InsertMany: " & $sResult & @CRLF)
		Exit 1
	EndIf
	ConsoleWrite("InsertMany Success: " & $sResult & @CRLF)

	$sResult = _Mongo_DeleteOne($pMongocollection,'{"application":"macos"}')
	If (@error) Then
		ConsoleWrite("TEST ERROR: DeleteOne: " & $sResult & @CRLF)
		Exit 1
	EndIf
	ConsoleWrite("DeleteOne Success: " & $sResult & @CRLF)

	$sResult = _Mongo_FindMany($pMongocollection, "{}", "{}")
	If (@error) Then
		ConsoleWrite("TEST ERROR: FindMany: " & $sResult & @CRLF)
		Exit 1
	EndIf
	;Iterate over cursor
	Local $sNext
	While (_Mongo_CursorNext($sResult,$sNext))
		ConsoleWrite("FindMany Next: " & $sNext & @CRLF)
	WEnd
	;Release cursor
	_Mongo_CursorDestroy($sResult)

EndFunc

#EndRegion mongodb.au3 - TESTS

