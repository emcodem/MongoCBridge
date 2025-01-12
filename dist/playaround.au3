#include <AutoItExitCodes.au3>
#include <Date.au3>
#include <file.au3>
#include <WinAPISys.au3>

#include "C:\dev\FFAStrans\Processors\_indep_funcs.au3"
#include "C:\dev\FFAStrans\Processors\_ffastrans_funcs.au3"

#include "MongoDB_UDF\MongoDB_SimpleJson.au3"
#include "_DB_FileFuncAbstraction.au3"
#include "MongoDB_UDF\MongoDB.au3"
#include "MongoDB_UDF\MongoDBConstants.au3"

#include <Debug.au3>
;_MongoRunTests()

;db.createUser({user:'ffastrans', pwd: 'ffasTrans', roles:["userAdminAnyDatabase","readWriteAnyDatabase"]})
;Local $small_jsonstr = '{"path":"/folder/subfolder/fname.json","wf_id":"0230625-1518-1896-1790-0dda9dfc0f34"}'

_Mongo_Init(@ScriptDir & "\MongoDB_UDF")
Local $s_mongo_url 		= "mongodb://localhost:27017"
Local $s_mongo_database_name 	= "ffastrans"
Local $s_mongo_collection_name 	= "db"
Local $pDB = _Mongo_CreateCollection($s_mongo_url, $s_mongo_database_name, $s_mongo_collection_name)

; Insert all Files from local to db
_Mongo_ClientCommandSimple($pDB, '{"drop": "'&$s_mongo_collection_name&'"}')
Files_To_DB_Recursive("C:\temp\ffastrans1407\Processors\db\","*.json;*.txt")
Exit(110564)

;random example aggregation, query all docs but return "mt" date formatted
Local $aggregation_FormatDate_Cmd ='[{"$match": {}}, {"$addFields": {"mt": {"$dateToString": {"format": "%Y-%m-%d %H:%M:%S", "date": "$mt"}}}}]' 

;Example: Ensure Indexes exist
Local $listIndexCmd = _Jkv("listIndexes",$s_mongo_collection_name)
Local $existing_idx = _Mongo_ClientCommandSimple($pDB,$listIndexCmd)
;~ If Not (StringInStr($existing_idx,'"idx_full"')) Then
;~     _Mongo_ClientCommandSimple($pDB,_MakeIndexCmd("full","idx_full",$s_mongo_collection_name,"true"))
;~ EndIf
;~ If Not (StringInStr($existing_idx,'"idx_name"')) Then
;~     _Mongo_ClientCommandSimple($pDB,_MakeIndexCmd("full","idx_name",$s_mongo_collection_name,"true"))
;~ EndIf
;~ If Not (StringInStr($existing_idx,'"idx_dir"')) Then
;~     _Mongo_ClientCommandSimple($pDB,_MakeIndexCmd("full","idx_dir",$s_mongo_collection_name,"true"))
;~ EndIf

;~ Local $aEmpty = 0
;~ MsgBox(0,0,UBound($aEmpty))
;~ exit(0)

;Distinct Example - get distinct list of all directories 
Local $aggregation_Distinct_cmd = '[{"$group": {"_id": "$dir" }}]'
Local $distinctCursor = _Mongo_Coll_Aggregate($pDB,$aggregation_Distinct_cmd)
Local $aResults = _Mongo_Cursor_To_Array($distinctCursor,"_id",0)

Local $begin = TimerInit()

Local $aFiles = _FileListToArrayRec("c:\temp\ffastrans1407\Processors\db\","*ab*.json",1,$FLTAR_RECUR,$FLTAR_SORT,0)
ConsoleWrite("local err; " & (@error) & @CRLF)
ConsoleWrite("local ext; " & (@extended) & @CRLF)
ConsoleWrite("local cnt; " & UBound($aFiles) & @CRLF)
ConsoleWrite("local type; " & VarGetType($aFiles) & @CRLF)
ConsoleWrite("local printed;" & $aFiles & ";" & @CRLF)
ConsoleWrite("Time:" & TimerDiff($begin) & @CRLF)
_ArrayDisplay($aFiles)

$begin = TimerInit()
Local $res = _DB_FileListToArrayRec($pDB,"*","*ab*.json",0,$FLTAR_RECUR,$FLTAR_SORT,0)
ConsoleWrite("db err; " & (@error) & @CRLF)
ConsoleWrite("db ext; " & (@extended) & @CRLF)
ConsoleWrite("DB cnt; " & UBound($res) & @CRLF)
ConsoleWrite("DB type; " & VarGetType($res) & @CRLF)
ConsoleWrite("DB printed;" & $aFiles & ";" & @CRLF)
ConsoleWrite("Time:" & TimerDiff($begin) & @CRLF)
_ArrayDisplay($res)

;~ Local $aDistinctDirs  = _Mongo_Cursor_To_Array($distinctCursor, "_id")
;~ _ArrayDisplay($aDistinctDirs)
Exit(10)
;FileList Example

;All Files to DB Example
Func Files_To_DB_Recursive($sPath = "C:\temp\ffastrans1407\Processors\db\",$sFilter = "*.json")

    Local $a_f = _FileListToArrayRec($sPath,$sFilter,1,1,1,2)
    For $i = 1 to UBound($a_f) -1
        Local $_f = $a_f[$i]

        If (StringRegExp($_f,".json$|.txt$","i")) Then
            ;Non Binary files
            Local $_h = FileOpen($_f,  $FO_READ)
            Local $_cont = FileRead($_h)
            FileClose($_h)
            ;empty json
            if (StringLen($_cont) = 0 And StringRegExp($_f,".json$","i")) Then
                $_cont = "{}"
            EndIf
            ;txt file
            if (StringRegExp($_f,".txt$","i")) Then
                $_cont = '"' & _JSafe($_cont) & '"'
            EndIf
            _DB_FileWrite($pDB,StringReplace($_f,$sPath,"\"),$_cont) ;REPLACES SEARCHPATH IN FULLPATH
            if (@error) Then
                ConsoleWrite("Write Text Error " & $_f & @CRLF);
            EndIf
        Else
            ;BINARY files
            Local $_h = FileOpen($_f,  16)
            If $_h = -1 Then
                MsgBox(16, "Error", "Failed to open the file: " & $_f)
                Exit
            EndIf
            Local $_cont = FileRead($_h)
            FileClose($_h)
            Local $binCont =  '"' & _JBase64Encode($_cont) & '"'
            ;DECODE:
            ;~ Local $bin = _Mongo_FindOne($pDB,"{}","{}","data.base64")
            ;~ $bin = _Base64Decode($bin)
            ;~ Local $hFile = FileOpen("c:\temp\test.bin",  $FO_OVERWRITE+ $FO_BINARY)
            ;~ FileWrite($hFile,($bin))
            _DB_FileWrite($pDB,StringReplace($_f,$sPath,"\"),$binCont)

            if (@error) Then
                ConsoleWrite("Write Binary Error " & $_f & @CRLF)
            EndIf
        EndIf

        if (@error) Then
            ConsoleWrite("Error writng " & $_f & "retry with string" & @CRLF)
        EndIf
        
    Next

EndFunc


Local $sResult
;_MongoRunTests()

;recreate collection for testing
;_Mongo_ClientCommandSimple($pMCCONFIGS, '{"drop": "'&$s_mongo_collection_name&'"}') 
;_Mongo_ClientCommandSimple($pMCCONFIGS, '{"create": "'&$s_mongo_collection_name&'"}') ; no need to create coll, it will be auto created
; ensures unique index, done only at startup or on new DB setup


Exit(11101)

Local $a_f = _FileListToArrayRec("C:\temp\ffastrans1407\Processors\db","*.json||jobs;mons",1,1,1,1)
_ArrayDisplay($a_f)

For $i = 1 to UBound($a_f) -1
    Local $_f = $a_f[$i]
    ConsoleWrite("File: " & $_f & @CRLF)
    Local $_cont = FileRead("C:\temp\ffastrans1407\Processors\db\" & $_f)
    
    _DB_FileWrite($pDB,$_f,$_cont)
Next

Exit (10001)

Local $hFind = _DB_FileFindFirstFile($pDB,"c:\temp\*\*.json")
If (@error) Then
    ConsoleWrite("First ERR: " & $hFind & @CRLF)
EndIf

While True
    Local $nextfile = _DB_FileFindNextFile(_DB_FileFindNextFile,$hFind)
    ConsoleWrite("Error Code: " & @error & @CRLF)
    if @error Then
        ConsoleWrite ("No more files" + @CRLF)
        ExitLoop
    EndIf
Wend

_DB_FileClose($hFind)

Exit (0)

#Region Write big file to db

Local $hFileOpen = FileOpen("C:\Users\Gam3r1\Downloads\2mb.json", $FO_UTF8 )
Local $filecont = FileRead ($hFileOpen)

if (@error) Then
	ConsoleWrite("Err" & @error & " " & $filecont)
	exit(1)
EndIf
FileClose($hFileOpen)

;retrieve all documents with formatted date example
Local $cursor   = _Mongo_Coll_Aggregate($pDB,'[{"$match": {}}, {"$addFields": {"mt": {"$dateToString": {"format": "%Y-%m-%d %H:%M:%S", "date": "$mt"}}}}]')
Local $aResults = _Mongo_Cursor_To_Array($cursor)

For $i = 1 To 1
	;Local $ret = _Mongo_GetJsonVal($filecont,"")
	_DB_FileWrite($pDB,"c:\temp\blabla\filename.json", $filecont)
    ;_DB_FileWrite("c:\temp\blabla\filename.json", _Jkv("test","1"))
    _MCheckErr()
    Local $res = _DB_FileRead($pDB,"c:\temp\blabla\filename.json")
    ConsoleWrite("===== Read res: " & StringLen($res) & @CRLF)
Next

ConsoleWrite("Time:" & TimerDiff($begin) & @CRLF)
Exit(0)


#EndRegion Write big file to db


Exit(0)


#Include <File.au3>
#Include <Array.au3>

Local $json_path_in = "C:\temp\ffastrans1407\Processors\db\configs\workflows"
Local $relpath 		= "workflows"
Local $aFileList = _FileListToArray($json_path_in, "*", 1)
Local $val

Exit(0)
For $i = 1 To $aFileList[0]
	If Not StringInStr ($aFileList[$i],"json") Then
	   ContinueLoop
	EndIf
	Local $hFileOpen = FileOpen($json_path_in & "\" &$aFileList[$i], $FO_UTF8 )
    $val = FileRead ($hFileOpen)

	if (@error) Then
		ConsoleWrite("Err" & @error & " " & $val)
		exit(1)
	EndIf
	ConsoleWrite($json_path_in & @CRLF)
	FileClose($hFileOpen)

	Local $dbdoc = Json_ObjCreate()
	Json_ObjPut($dbdoc,"path","workflows")
	Json_ObjPut($dbdoc,"name","sadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafdsadfasdfasfsafd")
	$dbdoc = Json_Encode_Compact($dbdoc)
	Local $ret = _Mongo_InsertOne($pDB,$dbdoc)
		if (@error) Then
			ConsoleWriteError("Errör: " & @error & $ret & @CRLF)
			exit(1)
		EndIf

	_Mongo_UpdateOne($pDB,'{"name":"'&$aFileList[$i]&'"}','{"$set":{"data":' & $val & '}}')

Next


;Example append JSON KV at position
;~ Local $sEmptyJ = '{"a":"val","b":{"c":"d"}}'
;~ MsgBox(0,"","")
;~ $sEmptyJ = _Mongo_AppendJsonKV($makeIndexCmd,"YIPIP","YEAH","indexes")
;~ ConsoleWrite($sEmptyJ & @CRLF)

;~ Func _Mongo_Exists($sPath)
;~ 	_Mongo_FindOne($pMCCONFIGS, $sQuery, $sProjection = "{}")
;~ EndFunc
Func _MCheckErr()
	if (@error) Then
		ConsoleWrite("Got Error " & @error & @CRLF)
		Exit(@error)
	EndIf
EndFunc

Func _Map2D(Const ByRef $mMap)
    Local $aMapKeys = MapKeys($mMap)
    Local $aMap2D[Ubound($aMapKeys)][2]

    Local $iRow = - 1
    For $vKey In $aMapKeys ; or a simple For... loop as commented out below
        $iRow += 1 ; 0+
        $aMap2D[$iRow][0] = $vKey
        $aMap2D[$iRow][1] = $mMap[$vKey]
    Next

;~  For $i = 0 To Ubound($aMapKeys) - 1
;~      $aMap2D[$i][0] = $aMapKeys[$i]
;~      $aMap2D[$i][1] = $mMap[$aMapKeys[$i]]
;~  Next

    Return $aMap2D
EndFunc


