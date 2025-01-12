; #INDEX# =======================================================================================================================
; Title .........: Tests for _DB_FileFuncAbstraction.au3
; AutoIt Version : 3.3.16.1
; Language ......: English
; Author(s) .....: emcodem
; Description ...: Requires mongodb running on 27017
;                   Extracts a test folder/file structure into ScriptDir \test_unzipped
;                   Inserts the files into DB and executes the Unit tests 
; ===============================================================================================================================

#include <Array.au3>
#include <File.au3>
#include <Date.au3>

#include "MongoDB_UDF\MongoDB.au3"
#include "MongoDB_UDF\MongoDB_SimpleJson.au3"
#include "_DB_FileFuncAbstraction.au3"

GLOBAL $iERRORS = 0
GLOBAL $iWARNINGS = 0
_Mongo_Init(@ScriptDir & "\MongoDB_UDF")
Local $s_mongo_url 		= "mongodb://localhost:27017"
Local $s_mongo_database_name 	= "tests"
Local $s_mongo_collection_name 	= "db"
Local $pDB = _Mongo_CreateCollection($s_mongo_url, $s_mongo_database_name, $s_mongo_collection_name)
_Mongo_ClientCommandSimple($pDB, '{"drop": "'&$s_mongo_collection_name&'"}')

GLOBAL $LOC_ROOT = @ScriptDir & "\test_unzipped"

#Region Prepare

;unzip test structure to $LOC_ROOT
DirCreate(@ScriptDir & "\test_unzipped") ; to extract to
Local $zipcmd = '"c:\Program Files\7-Zip\7z.exe"' & ' x "' & @ScriptDir & "\teststructure.zip" & '" ' & "-y -o" & '"' & @ScriptDir & "\test_unzipped" & '"'
ConsoleWrite($zipcmd & @CRLF)
RunWait($zipcmd, "", @SW_HIDE)
;local files to db
ConsoleWrite("Push Files to DB " & @CRLF)
__Files_To_DB_Recursive(@ScriptDir & "\test_unzipped\","*.json;*.txt")

#EndRegion Prepare

#Region Executing Tests

ConsoleWrite("Starting Tests..." & @CRLF)
Test__Misc()
ConsoleWrite(@CRLF & @CRLF & "==== MISC TEST FINISHED, ERRORS: " & $iERRORS & " Warnings: " & $iWARNINGS & " ====" &@CRLF & @CRLF)
$iERRORS = 0
$iWARNINGS = 0
Test__DB_FileListToArrayRec()
ConsoleWrite(@CRLF & @CRLF & "==== FileListToArrayRec TEST FINISHED, ERRORS: " & $iERRORS & " Warnings: " & $iWARNINGS & " ====" &@CRLF & @CRLF)

#EndRegion Executing Tests


################### Functions ###################
#Region MISC Tests
    Func Test__Misc()

        ; Read - Write - Delete

        Local $cont = _DB_FileRead($pDB,"\configs\ffastrans.json")
        UTAssert(@error = 0, "_DB_FileRead @error is " & @error)
        UTAssert(StringInStr($cont,"general"),"_DB_FileRead")

        Local $ret = _DB_FileDelete($pDB,"\configs\ffastrans.json")
        UTAssert(@error = 0, "_DB_FileDelete @error is " & @error)
        UTAssert($ret = True,"_DB_FileDelete, $ret is " & $ret)

        $ret = _DB_FileWrite($pDB,"\configs\ffastrans.json",$cont)
        UTAssert(@error = 0, "_DB_FileWrite @error is " & @error)
        UTAssert($ret = True,"_DB_FileWrite")

        ; Open - Read - Close
        Local $h = _DB_FileOpen($pDB,"\configs\ffastrans.json")
        UTAssert(@error = 0, "_DB_FileOpen @error is " & @error)
        UTAssert($h = 0, "_DB_FileOpen Handle is 0 ")

        Local $cont2 = _DB_FileRead($pDB,"\configs\ffastrans.json")
        UTAssert(@error = 0, "_DB_FileRead @error is " & @error)
        UTAssert(StringCompare($cont, $cont2), "_DB_FileRead Content changed")

        _DB_FileClose("\configs\ffastrans.json")
        UTAssert(UBound(MapKeys($_DB_OpenFileHandles)) = 0,"_DB_FileClose Error, " & UBound(MapKeys($_DB_OpenFileHandles)))

        ; FindFirst - Next
        $h = _DB_FileFindFirstFile($pDB,"\cache\tickets\running\*~*~*~*~*~*~*.json")
        UTAssert(@error = 0, "_DB_FileFindFirstFile @error is " & @error)
        UTAssert($h = 0, "_DB_FileFindFirstFile Handle is 0 ")

        Local $aFound[0]
        While True
            Local $nextfile = _DB_FileFindNextFile($pDB,$h) 
            if @error Then
                ExitLoop
            EndIf
            _ArrayAdd($aFound,$nextfile)
        Wend
        UTAssert(@error = 47, "_DB_FileFindNextFile @error is not 47 (no more files) but: " & @error)
        UTAssert(UBound($aFound) = 9, "_DB_FileFindNextFile count is not 9 but: " & UBound($aFound))
       

        ; BAD INPUT 
        Local $empty
        _DB_FileRead($pDB,"")
        UTAssert(@error = 1,"_DB_FileRead" & @error)
        _DB_FileRead($pDB,$empty)
        UTAssert(@error = 1,"_DB_FileRead" & @error)
        _DB_FileRead($empty,$empty)
        UTAssert(@error = 1,"_DB_FileRead" & @error)

        _DB_FileDelete($pDB,$empty)
        UTAssert(@error = 0,"_DB_FileDelete " & @error) ; TODDO: currently mongoc does not tell if doc was deleted

        _DB_FileWrite($pDB,"\configs\ffastrans.json",$empty)
        UTAssert(@error = 1,"_DB_FileWrite" & @error)
        _DB_FileWrite($pDB,$empty,$empty)
        UTAssert(@error = 1,"_DB_FileWrite" & @error)
        _DB_FileWrite($empty,$empty,$empty)
        UTAssert(@error = 1,"_DB_FileWrite" & @error)

        ;~ ; Open - Read - Close
        _DB_FileOpen($pDB,$empty)
        UTAssert(@error = 47,"_DB_FileOpen " & @error)
        _DB_FileOpen($empty,$empty)
        UTAssert(@error = 1,"_DB_FileOpen " & @error)

        _DB_FileRead($pDB,$empty)
        UTAssert(@error = 1,"_DB_FileRead " & @error)

        _DB_FileRead($empty,$empty)
        UTAssert(@error = 1,"_DB_FileRead " & @error)

        _DB_FileClose($empty)
        UTAssert(@error = 0,"_DB_FileClose " & @error) ; TODO: should this return error if not exist?

        _DB_FileFindFirstFile($pDB,$empty)        
        UTAssert(@error = 0,"_DB_FileFindFirstFile " & @error) ; TODO: should we validate if path exists? Currently findfirst works when searching empty

        _DB_FileFindFirstFile($empty,$empty) 
        UTAssert(@error = 1,"_DB_FileFindFirstFile " & @error)

        _DB_FileFindNextFile($pDB,$empty) 
        UTAssert(@error = 0,"_DB_FileFindNextFile " & @error) ; TODO: should we validate if path exists? Currently findfirst works when searching empty

        _DB_FileFindNextFile($empty,$empty) 
        UTAssert(@error = 1,"_DB_FileFindNextFile " & @error) 

    EndFunc

#EndRegion MISC Tests

#Region _DB_FileListToArrayRec Tests

Func Test__DB_FileListToArrayRec()
    ;A folder with subfolders, jsons and other files you want to test

    ;                   $iReturn        $FLTAR_FILESFOLDERS(0), $FLTAR_FILES(1) or $FLTAR_FOLDERS(2)
    ;                   $iRecur         $FLTAR_NORECUR (0) , $FLTAR_RECUR (1) 
    ;                   $iSort          $FLTAR_NOSORT (0) - Not sorted (Default), $FLTAR_SORT (1) - Sorted, $FLTAR_FASTSORT (2) same  as 1
    ;                   $iReturnPath    $FLTAR_NOPATH (0) - File/folder name only $FLTAR_RELPATH (1) - Relative to initial path (Default)  $FLTAR_FULLPATH (2) - Full path included

    Local $aParams[5][10] = [ [ $FLTAR_FILES,   $FLTAR_RECUR,   $FLTAR_SORT, $FLTAR_NOPATH,     $LOC_ROOT & "\configs", "\configs", "*.json" ] _
                            , [ $FLTAR_FILES,   $FLTAR_RECUR,   $FLTAR_SORT, $FLTAR_RELPATH,    $LOC_ROOT & "\cache\tickets", "\cache\tickets", '*~20250112-1427-0825-832c-f381f3961998~*~*~*~*~*.json||pending' ] _ ;_FileListToArrayRecL($s_SYS_CACHE_DIR & '\tickets', '*~' & $s_JOB_GUID & '~*~*~*~*~*.json||pending', 1, 1)
                            , [ $FLTAR_FOLDERS, $FLTAR_NORECUR, $FLTAR_SORT, $FLTAR_RELPATH,    $LOC_ROOT & "\cache\jobs", "\cache\jobs", "*" ] _ ; Local $a_dir_list = _FileListToArrayRecL($s_SYS_CACHE_DIR & '\jobs', '*', 2, 0, 1, 1)
                            , [ $FLTAR_FILES,   $FLTAR_RECUR,   $FLTAR_SORT, $FLTAR_RELPATH,    $LOC_ROOT & "\configs", "\configs", "*.json" ] _
                            , [ $FLTAR_FILES,   $FLTAR_RECUR,   $FLTAR_SORT, $FLTAR_RELPATH,    $LOC_ROOT & "\configs\invalid", "\configs\invalid", "*.json" ]] 

    Local $err1
    Local $err2
    Local $ext1
    Local $ext2

    For $i = 0 to UBound($aParams)-1
        ConsoleWrite(@CRLF & "Executing Test #" & $i & @CRLF)
        ConsoleWrite("# Local Path: " & $aParams[$i][4] & @CRLF)
        ConsoleWrite("# DB    Path: " & $aParams[$i][5] & @CRLF)
        ConsoleWrite("#Filter     : " & $aParams[$i][6] & @CRLF)
        
        ;4 = localroot, 5 = dbroot, 6= mask
        Local $aFromLocal = _FileListToArrayRec($aParams[$i][4],$aParams[$i][6],        $aParams[$i][0],$aParams[$i][1],$aParams[$i][2],$aParams[$i][3])
        $err1 = @error
        $ext1 = @extended
        Local $aFromMongo = _DB_FileListToArrayRec($pDB,$aParams[$i][5],$aParams[$i][6],   $aParams[$i][0],$aParams[$i][1],$aParams[$i][2],$aParams[$i][3])
        $err2 = @error
        $ext2 = @extended
        UTAssert(UBound($aFromLocal) > 0," size Test #" & $i, @ScriptLineNumber, True)
        CompareArrays($aFromLocal,$aFromMongo," >>> Compare Test #" & $i, @ScriptLineNumber)
        UTAssert($err1 = $err2, "@error, left: " &$err1 & ", right: " &$err2)
        UTAssert($ext1 = $ext2, "@extended, left: " &$ext1 & ", right: " &$ext2)
    Next

EndFunc

#EndRegion _DB_FileListToArrayRec Tests

################### HELPERS ###################

#Region Helpers
Func CompareArrays($a1,$a2,$message,$scriptline)
    ;_ArrayDisplay($a1,"Locald Final Res")
    _ArraySort($a1, 0, 1) ;in filesfolders mode, ffastrans sorts per folder but db always sorts the whole array, we ignore this difference
    ConsoleWrite("Compare Size Left:" & UBound($a1) & " | Size Right:" & UBound($a2) & @CRLF)
    UTAssert(UBound($a1) = UBound($a2), $message & " Size mismatch: [" & UBound($a1) &  "] [" & UBound($a2) & "]",$scriptline)
    For $i = 1 to UBound($a1) -1
        UTAssert($a1[$i] = $a2[$i],$message & " Entry ["&$i&"] mismatch: [" & $a1[$i] &  "] [" & $a2[$i] & "]",$scriptline)
    Next
EndFunc

Func UTAssert(Const $bool, Const $msg = "Assert Failure", Const $erl = @ScriptLineNumber, Const $warn = False)
	If Not $bool Then
        if Not $warn Then
		    $iERRORS = $iERRORS + 1
            ConsoleWrite("(" & $erl & ") ERROR := " & $msg & @CRLF)
        Else
            $iWARNINGS = $iWARNINGS + 1
            ConsoleWrite("(" & $erl & ") WARNING := " & $msg & @CRLF)
        EndIf
	EndIf
	
	Return $bool
EndFunc   ;==>UTAssert

Func __ExtractZip($sZipFile, $sDestinationFolder, $sFolderStructure = "")

    Local $i
    Do
        $i += 1
        Local $sTempZipFolder = @TempDir & "\Temporary Directory " & $i & " for " & StringRegExpReplace($sZipFile, ".*\\", "")
    Until Not FileExists($sTempZipFolder) ; this folder will be created during extraction

    Local $oShell = ObjCreate("Shell.Application")

    If Not IsObj($oShell) Then
        Return SetError(1, 0, 0) ; highly unlikely but could happen
    EndIf

    Local $oDestinationFolder = $oShell.NameSpace($sDestinationFolder)
    If Not IsObj($oDestinationFolder) Then
        DirCreate($sDestinationFolder)
;~         Return SetError(2, 0, 0) ; unavailable destionation location
    EndIf

    Local $oOriginFolder = $oShell.NameSpace($sZipFile & "\" & $sFolderStructure) ; FolderStructure is overstatement because of the available depth
    If Not IsObj($oOriginFolder) Then
        Return SetError(3, 0, 0) ; unavailable location
    EndIf

    Local $oOriginFile = $oOriginFolder.Items();get all items
    If Not IsObj($oOriginFile) Then
        Return SetError(4, 0, 0) ; no such file in ZIP file
    EndIf

    ; copy content of origin to destination
    $oDestinationFolder.CopyHere($oOriginFile, 20) ; 20 means 4 and 16, replaces files if asked

    DirRemove($sTempZipFolder, 1) ; clean temp dir

    Return 1 ; All OK!

EndFunc


Func __Files_To_DB_Recursive($sPath,$sFilter = "*.json")

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
            ;ConsoleWrite(StringReplace($_f,$sPath,"\") & @CRLF)
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


#EndRegion Helpers