#include <AutoItExitCodes.au3>
#include <Date.au3>
#include <file.au3>
#include <WinAPISys.au3>
#include "C:\dev\FFAStrans\Processors\_indep_funcs.au3"
#include "C:\dev\FFAStrans\Processors\_ffastrans_funcs.au3"

#include "MongoDB_UDF\MongoDB_Test.au3"
#include "MongoDB_UDF\MongoDB.au3"
_Mongo_Init(@ScriptDir & "\MongoDB_UDF")
#include <Debug.au3>
;_MongoRunTests()

;db.createUser({user:'ffastrans', pwd: 'ffasTrans', roles:["userAdminAnyDatabase","readWriteAnyDatabase"]})
;Local $small_jsonstr = '{"path":"/folder/subfolder/fname.json","wf_id":"0230625-1518-1896-1790-0dda9dfc0f34"}'

Global $_DB_NextHandles[]
Local $s_mongo_url 		= "mongodb://localhost:27017"
Local $s_mongo_database_name 	= "ffastrans"
Local $s_mongo_collection_name 	= "configs"
Local $sResult
;_MongoRunJsonTests()
;Initialize mongodb driver
MsgBox(0,0,0)
Local $pMCCONFIGS = _Mongo_CreateCollection($s_mongo_url, $s_mongo_database_name, $s_mongo_collection_name)

Local $listIndexCmd = _Jkv("listIndexes",$s_mongo_collection_name) ;List indexes example
Local $makeIndexCmd = '{"createIndexes": "'&$s_mongo_collection_name&'","indexes": [{"key":{ "full": 1 },"name": "'&$s_mongo_collection_name&'","unique": true}]}' ; make field unique forced example
Local $aggregation_FormatDate_Cmd ='[{"$match": {}}, {"$addFields": {"mt": {"$dateToString": {"format": "%Y-%m-%d %H:%M:%S", "date": "$mt"}}}}]' ;retrieve mt date as formatted string example
Local $begin = TimerInit()

;_MongoRunTests()

;recreate collection for testing
;_Mongo_ClientCommandSimple($pMCCONFIGS, '{"drop": "'&$s_mongo_collection_name&'"}') 
;_Mongo_ClientCommandSimple($pMCCONFIGS, '{"create": "'&$s_mongo_collection_name&'"}') ; no need to create coll, it will be auto created
; ensures unique index, done only at startup or on new DB setup
_Mongo_ClientCommandSimple($pMCCONFIGS,$makeIndexCmd)

Local $a_f = _FileListToArrayRec("C:\temp\ffastrans1407\Processors\db","*.json||jobs;mons",1,1,1,1)
_ArrayDisplay($a_f)

For $i = 1 to UBound($a_f) -1
    Local $_f = $a_f[$i]
    ConsoleWrite("File: " & $_f & @CRLF)
    Local $_cont = FileRead("C:\temp\ffastrans1407\Processors\db\" & $_f)
    
    _DB_FileWrite($_f,$_cont)
Next

Local $hFind = _DB_FileFindFirstFile("c:\temp\*\*.json")
If (@error) Then
    ConsoleWrite("First ERR: " & $hFind & @CRLF)
EndIf

While True
    Local $nextfile = _DB_FileFindNextFile($hFind)
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
Local $cursor   = _Mongo_Coll_Aggregate($pMCCONFIGS,'[{"$match": {}}, {"$addFields": {"mt": {"$dateToString": {"format": "%Y-%m-%d %H:%M:%S", "date": "$mt"}}}}]')
Local $aResults = _Mongo_Cursor_To_Array($cursor)

For $i = 1 To 1
	;Local $ret = _Mongo_GetJsonVal($filecont,"")
	_DB_FileWrite("c:\temp\blabla\filename.json", $filecont)
    ;_DB_FileWrite("c:\temp\blabla\filename.json", _Jkv("test","1"))
    _MCheckErr()
    Local $res = _DB_FileRead("c:\temp\blabla\filename.json")
    ConsoleWrite("===== Read res: " & StringLen($res) & @CRLF)
Next

ConsoleWrite("Time:" & TimerDiff($begin) & @CRLF)
Exit(0)


#EndRegion Write big file to db


;~ $sFilePath	Initial path used to generate filelist.
;~ If path ends in \ then folders will be returned with an ending \
;~ If path lengths > 260 chars, prefix path with "\\?\" - return paths are not affected

;~ $sMask	[optional] Filter for result. Multiple filters must be separated by ";"
;~ Use "|" to separate 3 possible sets of filters: "Include|Exclude|Exclude_Folders"
;~     Include = Files/Folders to include (default = "*" [all])
;~     Exclude = Files/Folders to exclude (default = "" [none])
;~     Exclude_Folders = only used if $iRecur = 1 AND $iReturn <> 2 to exclude defined folders (default = "" [none])

;~ $iReturn	[optional] Specifies whether to return files, folders or both and omit those with certain attributes
;~     $FLTAR_FILESFOLDERS (0) - (Default) Return both files and folders
;~     $FLTAR_FILES (1) - Return files only
;~     $FLTAR_FOLDERS (2) - Return Folders only
;~ Add one or more of the following to $iReturn to omit files/folders with that attribute
;~     + $FLTAR_NOHIDDEN (4) - Hidden files and folders
;~     + $FLTAR_NOSYSTEM (8) - System files and folders
;~     + $FLTAR_NOLINK (16) - Link/junction folders

;~ $iRecur	[optional] Specifies whether to search recursively in subfolders and to what level
;~     $FLTAR_NORECUR (0) - Do not search in subfolders (Default)
;~     $FLTAR_RECUR (1) - Search in all subfolders (unlimited recursion)
;~ Negative integer - Search in subfolders to specified depth

;~ $iSort	[optional] Sort results in alphabetical and depth order
;~     $FLTAR_NOSORT (0) - Not sorted (Default)
;~     $FLTAR_SORT (1) - Sorted
;~     $FLTAR_FASTSORT (2) - Sorted with faster algorithm (assumes files in folder returned sorted - requires NTFS and not guaranteed)

;~ $iReturnPath	[optional] Specifies displayed path of results
;~     $FLTAR_NOPATH (0) - File/folder name only
;~     $FLTAR_RELPATH (1) - Relative to initial path (Default)
;~     $FLTAR_FULLPATH (2) - Full path included


Func _InitFileEntry($sPath, $sDataJSON)
    Local $szDrive, $szDir, $szFName, $szExt
    _PathSplit($sPath, $szDrive, $szDir, $szFName, $szExt)
    Local $modified = @YEAR & '-' & @MON & '-' & @MDAY & 'T' & @HOUR & ':' & @MIN & ':' & @SEC & '.' & @MSEC & "+01:00" ;todo: use correct gmt bias!
    Local $_onInsert = '"$setOnInsert": {"ct": { "$date": "' & $modified & '" }' ;sets creation time only if document does not exist
    Local $_mt = '"mt": { "$date": "' & $modified & '" }'
    ;research shows this is the fastest way to create this with large DataJSON
	Local $s = '{"$set":{' & $_mt & ' ,"name":"'&_JSafe($szFName)&'","dir":"'&_JSafe($szDir) & '","full":"'&_JSafe($sPath) & '","data":' & $sDataJSON & '},' & $_onInsert & '}}'
	return $s
EndFunc

Func _DB_FileOpen($sPath,$_mode = 0)
    ; if doc exsists, just return the original path so it will be used in fileread
    ; Modes gt 511 are encodings we dont yet support here.
    If ($_mode > 511) Then
        SetError(511,511,"_DB_FileOpen does not support mode " & $_mode)
    Endif
    Local $doc = _Mongo_FindOne($pMCCONFIGS, _Jkv("name", $sPath),'{"data":1}')
    If @error Then
        SetError(@error, @extended, $doc)
        return -1
    EndIf
    ;File exists, we return the return path because the calling function will use it as "handle" which renders to using the path directly in filewrite
    return $sPath
EndFunc

Func _DB_FileWrite($sPath, $sData)
    ; Upserts mongo doc, todo: support flags?
    
    Local $sUpdate = _InitFileEntry($sPath,$sData)
    ConsoleWrite("Writing " & $sPath & @CRLF)
	_Mongo_UpdateOne($pMCCONFIGS, _Jkv("full", $sPath), $sUpdate, '{"upsert":true}')
    If @error Then
        exit(1)
        ConsoleWrite(@CRLF & @CRLF & "Error updating file " & $sPath & @CRLF & @CRLF)
		Return SetError(@error, @extended, "")
    EndIf
    
    return $sPath
EndFunc

Func _DB_FileRead($sPath)
    ; Check if the document exists in the collection
    Local $data = _Mongo_FindOne($pMCCONFIGS, _Jkv("full", $sPath))
    If @error Then
        ConsoleWrite("Error reading file [" & $spath & "], " & @error)
        Return ""
    EndIf
    return $data
EndFunc


Func _DB_FileFindFirstFile($sPath)
    Local $szDrive, $szDir, $szFName, $szExt
    _PathSplit($sPath, $szDrive, $szDir, $szFName, $szExt)
    
    Local $m[]
    $m.served = 0
    
    $_DB_NextHandles[$sPath] = $m
    Local $rgx = _DB_RegexEscape($sPath)
    Local $query = '{"full": { "$regex": "' & _JSafe($rgx) & '", "$options": "i" }}'
    Local $found = _Mongo_FindOne($pMCCONFIGS, $query, '{"projection":{"_id":1}}', "data")
    ConsoleWrite("Found first: " & $found & @CRLF)
    If (@error) Then
        return SetError(@error)
    EndIf
    return $sPath
EndFunc

Func _DB_FileFindNextFile($h)
    ;todo: check if handle exists
    ;"handle" is original search path
    
    Local $rgx = _DB_RegexEscape($h)
    Local $query = '{"full": { "$regex": "' & _JSafe($rgx) & '", "$options": "i" }}'
    Local $found = _Mongo_FindOne($pMCCONFIGS, $query, '{"skip":' & $_DB_NextHandles[$h].served & '}', "data")
    If (@error) Then
        return SetError(@error)
    EndIf
    $_DB_NextHandles[$h].served = $_DB_NextHandles[$h].served + 1 
    return $found
EndFunc

Func _DB_FileClose($h)
    MapRemove ( $_DB_NextHandles, $h )
EndFunc

Func _DB_RegexEscape($s)
    ;apply regex for mongo search and mimic windows explorer behaviour
    Local $rgx = StringReplace($s,"\","\\")
    $rgx = StringReplace($rgx,".","\.")
    $rgx = StringReplace($rgx,"*",".*")
    return $rgx
EndFunc

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
	Local $ret = _Mongo_InsertOne($pMCCONFIGS,$dbdoc)
		if (@error) Then
			ConsoleWriteError("Errör: " & @error & $ret & @CRLF)
			exit(1)
		EndIf

	_Mongo_UpdateOne($pMCCONFIGS,'{"name":"'&$aFileList[$i]&'"}','{"$set":{"data":' & $val & '}}')

Next


;Example append JSON KV at position
Local $sEmptyJ = '{"a":"val","b":{"c":"d"}}'
MsgBox(0,"","")
$sEmptyJ = _Mongo_AppendJsonKV($makeIndexCmd,"YIPIP","YEAH","indexes")
ConsoleWrite($sEmptyJ & @CRLF)

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

#Region Simple Json helpers

Func _Jkv($key,$val)
	return StringFormat('{"%s":"%s"}', _JSafe($key), _JSafe($val))
EndFunc

Func _Jkj($key,$val)
	return StringFormat('{"%s":%s}', _JSafe($key), $val)
EndFunc

Func _JSafe($sString)
    ; Initialize the escaped string
    Local $sEscapedString = ""

    ; Loop through each character in the input string
    For $i = 1 To StringLen($sString)
        Local $char = StringMid($sString, $i, 1)

        ; Check for special JSON characters and escape them
        Switch $char
            Case '"'
                $sEscapedString &= '\"'
            Case '\'
                $sEscapedString &= '\\'
            Case '/'
                $sEscapedString &= '\/'
            Case Chr(8) ; Backspace
                $sEscapedString &= '\b'
            Case Chr(12) ; Formfeed
                $sEscapedString &= '\f'
            Case Chr(10) ; Newline
                $sEscapedString &= '\n'
            Case Chr(13) ; Carriage return
                $sEscapedString &= '\r'
            Case Chr(9) ; Tab
                $sEscapedString &= '\t'
			Case Else    ; If the character is non-printable, encode it as \uXXXX
                If Asc($char) < 32 Or Asc($char) > 126 Then
                    $sEscapedString &= "\\u" & StringFormat("%04X", Asc($char))
                Else
                    ; Otherwise, append the character as is
                    $sEscapedString &= $char
                EndIf
        EndSwitch
    Next

    Return $sEscapedString
EndFunc

#EndRegion Simple JSON helpers


