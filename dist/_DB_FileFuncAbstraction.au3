
#include <Array.au3>
#include <File.au3>
#include <Date.au3>
#include "MongoDB_UDF\MongoDB.au3"
#include "MongoDB_UDF\MongoDB_SimpleJson.au3"

; #CONSTANTS# ===================================================================================================================

Global $_DB_NextHandles[]
Global $_DB_OpenFileHandles[]

; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: _DB_FileDelete
; Description ...: Mimic behaviour of FileDelete
; Syntax.........: _DB_FileDelete($pDB,$sPath)
; Parameters ....:  $pDB Pointer to Mongo Collection 
;   				$sPath Full path
; Return values .: Bool 
; Author ........: emcodem
Func _DB_FileDelete($pDB,$sPath)
    Local $res = _Mongo_DeleteOne($pDB,'{"full":"'&_JSafe($sPath)&'"}')
    if (@error) Then
        return SetError(@error)
    EndIf
    return $res
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _DB_FileListToArrayRec
; Description ...: Mimic behaviour of FileListToArrayRec
; Syntax.........: _DB_FileListToArrayRec($pDB, $sFilePath , $sMask = "*" , $iReturn = $FLTAR_FILESFOLDERS , $iRecur = $FLTAR_NORECUR , $iSort = $FLTAR_NOSORT , $iReturnPath = $FLTAR_RELPATH)
; Parameters ....:  $pDB Pointer to Mongo Collection 
;   				$sFilePath Root Path
;					$sMask as in _DB_FileListToArrayRec
;                   $iReturn        $FLTAR_FILESFOLDERS(0), $FLTAR_FILES(1) or $FLTAR_FOLDERS(2)
;                   $iRecur         $FLTAR_NORECUR (0) , $FLTAR_RECUR (1) 
;                   $iSort          $FLTAR_NOSORT (0) - Not sorted (Default), $FLTAR_SORT (1) - Sorted, $FLTAR_FASTSORT (2) same  as 1
;                   $iReturnPath    $FLTAR_NOPATH (0) - File/folder name only $FLTAR_RELPATH (1) - Relative to initial path (Default)  $FLTAR_FULLPATH (2) - Full path included
; Return values .: Array
; Author ........: emcodem
; Remarks .......: Releases the Cursor _Mongo_CursorDestroy when done
; ===============================================================================================================================
Func _DB_FileListToArrayRec($pDB, $sFilePath , $sMask = "*" , $iReturn = $FLTAR_FILES, $iRecur = $FLTAR_NORECUR , $iSort = $FLTAR_NOSORT , $iReturnPath = $FLTAR_RELPATH)
    ;$sMask = Include|Exclude|Exclude_Folders
    If ($iReturn > 2) Then 
        return SetError(1,5,"") 
    EndIf
    If ($iRecur > 1) Then 
        return SetError(1,6,"") 
    EndIf
    
    ;~ validate and parse sMask
    Local $aMask = StringSplit ($sMask,'|')
    Local $sInc     = $aMask[0] > 0 ? $aMask[1] : "*"
    Local $sExc     = $aMask[0] > 1 ? $aMask[2] : ""
    Local $sExcDir  = $aMask[0] > 2 ? $aMask[3] : ""
 
    If ($sExc <> "") Then
        $sExc = _DB_FLTAR_RegexEscape("^" & $sExc & "$")
    EndIf
    If ($sExcDir <> "") Then
        $sExcDir = _DB_FLTAR_RegexEscape($sExcDir)
    EndIf

    ;~ validate Searchpath
    if ($sFilePath <> "") Then
        $sFilePath = _DB_FLTAR_EnsureBackslashEnd($sFilePath)
        $sFilePath = _DB_FLTAR_EnsureBackslashStart($sFilePath)
    EndIf

    Local $aResult[1] = [0] ;count field
    If ($iReturn = $FLTAR_FILES) Or ($iReturn = $FLTAR_FILESFOLDERS) Then
        Local $s_dirrgx = $sFilePath
        ;~ RECURSE
        If ($iRecur = $FLTAR_NORECUR) Then
            $s_dirrgx = "^" & $sFilePath & "$"
        EndIf
        $s_dirrgx = _DB_FLTAR_RegexEscape($s_dirrgx)

        ;Construct query
        Local $sIncRgx = _DB_FLTAR_RegexEscape("^" & $sInc & "$")
        Local $query = '{'
        $query &= '"dir": { "$regex": "' & _JSafe($s_dirrgx) & '", "$options": "i" }'
        $query &= ',"name": { "$regex": "' & _JSafe($sIncRgx) & '", "$options": "i" }'
        If ($sExc <> "") Then
            $query &= ',"name": {"$not": {"$regex": "' & _JSafe($sExc) & '", "$options": "i" }}'
        EndIf
        If ($sExcDir <> "") Then
            $query &= ',"dir":  {"$not": {"$regex": "' & _JSafe($sExcDir) & '", "$options": "i" }}'
        EndIf
        $query &= '}'

        ;QUERY THE DB FOR FILES
        ;ConsoleWrite("QUERY === " & $query & @CRLF)
        Local $pCursor = _Mongo_FindMany($pDB,$query,'{}') ; could sort here opts={sort:{"full":-1}}
        If (@error) Then
            return SetError(1,9) 
        EndIf
        
        Local $sReturnField = "full"
        If ($iReturnPath = $FLTAR_NOPATH) Then
            $sReturnField = "name"
        EndIf

        $aResult = _Mongo_Cursor_To_Array($pCursor,$sReturnField,True)
        If (@error) Then
            return SetError(1,9) 
        EndIf
    EndIf ;~ files or files and folders

    ;QUERY DB FOR FOLDERS
    ;If (UBound($aResult ) <> 0 AND (($iReturn = $FLTAR_FILESFOLDERS) OR ($iReturn = $FLTAR_FOLDERS))) Then
    If (($iReturn = $FLTAR_FILESFOLDERS) OR ($iReturn = $FLTAR_FOLDERS)) Then
        ;get all distinct folders from db
        Local $noRecurRgx = _DB_FLTAR_RegexEscape("^" & $sFilePath ) & "[^\\]+\\?$";  regex allows only one folder down
        Local $sDistinct = '['
        $sDistinct &= $iRecur = 0 ? '{ "$match" : {"dir":   {"$regex": "' & _JSafe($noRecurRgx) & '", "$options": "i" }}},' : "" ; if no recurse, only include one sub
        $sDistinct &= '{"$group": {"_id": "$dir" }}' ;creates distinct list
        $sDistinct &= ']'
        Local $distinctCursor = _Mongo_Coll_Aggregate($pDB,$sDistinct)
        Local $aFolders = _Mongo_Cursor_To_Array($distinctCursor,"_id",False)
        
        ;some parent folders might not be registered in db because there are no files in them, resolve those
        Local $aParents = __ResolveParentFolders($aFolders)
        _ArrayConcatenate ($aFolders, $aParents)
        If (UBound($aFolders) = 0) Then
            return SetError(1,1)
        EndIf
        ;remove dups and apply include filter
        Local $mUnique[]
        For $i = 0 to UBound($aFolders) -1
            ;ConsoleWrite("Folder regex " & $aFolders[$i] & " ? " & _DB_RegexEscape($sFilePath) & @CRLF)
            if (StringRegExp($aFolders[$i],_DB_RegexEscape($sFilePath)) _
                And $aFolders[$i] <> $sFilePath) Then
                ;ConsoleWrite("Adding Folder Entry: " & $aFolders[$i] & @CRLF)
                If(StringRight($aFolders[$i],1) = "\") Then
                    $aFolders[$i] = StringTrimRight($aFolders[$i] ,1)
                EndIf
                
                $mUnique[$aFolders[$i]] = 1
            EndIf
        Next

        ;finally add the folders to the result array
        Local $aUnique = MapKeys($mUnique)
        ;ConsoleWrite("UNIQUE " & UBound($aUnique) & "Current " & UBound($aResult))
        
        _ArrayConcatenate ($aResult, $aUnique)
        If (UBound($aResult) > 0) Then
            $aResult[0] = UBound($aResult)-1
        EndIf
    EndIf
    
    If (UBound($aResult) = 0) Then
        return SetError(1,1,"") ;FileListToArrayRec seems to return like this when empty
    EndIf
    
    ;relative return path?
    If ($iReturnPath = $FLTAR_RELPATH) Then 
        For $i = 1 to UBound($aResult)-1
            if ($sFilePath <> "") Then
                $aResult[$i] = StringReplace($aResult[$i],$sFilePath,"")
            EndIf
            if (StringLeft($aResult[$i], 1) = "\") Then
                $aResult[$i] = StringTrimLeft($aResult[$i], 1) ;remvoe start backslash
            EndIf        
        Next
    EndIf
    
    ;Sort - we could sort faster in mongo but it would not yield the exact same result
    If ($iSort <> $FLTAR_NOSORT) Then
        _ArraySort($aResult, 0, 1)
    EndIf

    return $aResult

EndFunc

Func __ResolveParentFolders($aFolders)
    ;if we have /a/b/c in mongo, add a,a\b,a\b\c to the array
    Local $dirs[] ;Map with separate folders
    For $i = 0 to UBound($aFolders) -1
        Local $aparts = StringSplit($aFolders[$i], "\",2)
        Local $_x
        While UBound($aparts) > 0
            Local $s_p = __ArrayPop($aparts)
            Local $sJoined = _ArrayToString($aparts, "\")
            If ($sJoined = "") Then
                ContinueLoop
            EndIf
            $dirs[$sJoined ] = $sJoined & "\"
        WEnd    
    Next
    ;_ArrayDisplay(__Map2D($dirs))
    ;iterate map and create array for return, discard empty
    Local $aDirs[UBound($dirs)]
    Local $iCnt = 0
    For $vKey In $dirs 
        If ($vKey <> "") Then
            $aDirs[$iCnt] = $vKey
            $iCnt = $iCnt + 1
        EndIf
    Next
    _ArrayDelete($aDirs, $iCnt & "-" & UBound($aDirs)-1)
    return $aDirs
EndFunc

Func __ArrayPop(ByRef $aArray)
    If UBound($aArray) = 0 Then
        Return SetError(1, 0, "") ; Return an empty string and set an error if the array is empty
    EndIf
    
    Local $vLastElement = $aArray[UBound($aArray) - 1] ; Get the last element
    ReDim $aArray[UBound($aArray) - 1] ; Resize the array to remove the last element
    Return $vLastElement ; Return the removed element
EndFunc


Func __Map2D(Const ByRef $mMap)
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


; #FUNCTION# ====================================================================================================================
; Name...........: _DB_FileWrite
; Description ...: Mimic behaviour of FileListToArrayRec
; Syntax.........: _DB_FileWrite($pDB,$sPath, $sData)
; Parameters ....:  $pDB Pointer to Mongo Collection 
;   				$sPath path and filename
;                   $sData 
; Return values .: Array
; Author ........: emcodem
; Remarks .......: Releases the Cursor _Mongo_CursorDestroy when done
; ===============================================================================================================================
Func _DB_FileWrite($pDB,$sPath, $sData)
    ; Upserts mongo doc, todo: support flags?

    Local $sUpdate = __InitFileEntry($sPath,$sData)

    ;ConsoleWrite("== QUERY " & $sUpdate & "==" & @CRLF)
	_Mongo_UpdateOne($pDB, _Jkv("full", $sPath), $sUpdate, '{"upsert":true}')
    If @error Then
        ConsoleWrite(@CRLF & @CRLF & "Error updating file " & $sPath & @CRLF & @CRLF)
		Return SetError(@error, @extended, "")
    EndIf
    
    return $sPath
EndFunc

;~ ; #FUNCTION# ====================================================================================================================
;~ ; Name...........: _DB_FileOpen
;~ ; Description ...: Mimic behaviour of FileSetPos
;~ ; Syntax.........: _DB_FileOpen ($pDB,$sPath,$_mode = 0)
;~ ; Parameters ....:  $sPath Path and filename as stored in "full" field
;~ ;                   $_mode (binary mode not yet implemented)
;~ ; Return values .: Bool
;~ ; Author ........: emcodem
;~ ; ===============================================================================================================================
Func _DB_FileOpen($pDB,$sPath,$_mode = 0)
    ; if doc exsists, just return the original path so it will be used in fileread
    ; Modes gt 511 are encodings we dont yet support here.
    If ($_mode > 511) Then
        SetError(511,511,"_DB_FileOpen does not support mode " & $_mode)
    Endif
    Local $doc = _Mongo_FindOne($pDB, _Jkv("full", $sPath),'{"projection":{"_id":1}}',"data")
    If @error Then
        return SetError(@error, @extended, $doc)
    EndIf
    Local $m[]
    $m.usecount = 0
    $_DB_OpenFileHandles[$sPath] = $m
    ;File exists, we return the return path because the calling function will use it as "handle" which renders to using the path directly in filewrite
    return $sPath
EndFunc

;~ ; #FUNCTION# ====================================================================================================================
;~ ; Name...........: _DB_FileSetPos
;~ ; Description ...: Mimic behaviour of FileSetPos
;~ ; Syntax.........: _DB_FileSetPos ($sPath,$iCount)
;~ ; Parameters ....:  $sPath Path and filename as stored in "full" field
;~ ;                   $iCount Count of characters to read 
;~ ; Return values .: Bool
;~ ; Author ........: emcodem
;~ ; ===============================================================================================================================
;~ Func _DB_FileSetPos($sPath,$iCount)
;~     If Not (MapExists ( $_DB_NextHandles, $sPath )) Then
;~         return False
;~     EndIf
;~     $_DB_NextHandles[$sPath].pos = $iCount
;~ EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _DB_FileRead
; Description ...: Mimic behaviour of FileRead
; Syntax.........: _DB_FileRead ( "filehandle/filename" [, count] )
; Parameters ....:  $pDB Pointer to Mongo Collection 
;   				$sPath Path and filename as stored in "full" field
;                   $iCount Not implemented yet
; Return values .: String or Binary
; Author ........: emcodem
; ===============================================================================================================================
Func _DB_FileRead($pDB,$sPath,$iCount = 0)
    ; Check if the document exists in the collection
    Local $data = _Mongo_FindOne($pDB, _Jkv("full", $sPath))
    If @error Then
        return SetError(1)
    EndIf

    return $data
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _DB_FileFindFirstFile
; Description ...: Mimic behaviour of FileReaFileFindFirstFiled
; Syntax.........: _DB_FileFindFirstFile ($pDB,$sPath)
; Parameters ....:  $pDB Pointer to Mongo Collection 
;   				$sPath Path and filename as stored in "full" field
; Return values .: String or Binary
; Author ........: emcodem
; ===============================================================================================================================
Func _DB_FileFindFirstFile($pDB,$sPath)
    Local $szDrive, $szDir, $szFName, $szExt
    _PathSplit($sPath, $szDrive, $szDir, $szFName, $szExt)
       
    Local $rgx = _DB_RegexEscape($sPath)
    Local $query = '{"full": { "$regex": "' & _JSafe($rgx) & '", "$options": "i" }}'
    Local $found = _Mongo_FindOne($pDB, $query, '{"projection":{"_id":1}}', "data")
    
    If (@error) Then
        return SetError(@error)
    EndIf
    Local $m[]
    $m.served = 0
    $_DB_NextHandles[$sPath] = $m
    return $sPath
EndFunc

Func _DB_FileFindNextFile($pDB,$h)
    ;todo: check if handle exists
    ;"handle" is original search path
    If Not MapExists ($_DB_NextHandles,$h) Then
        return SetError(1)
    EndIf
    Local $rgx = _DB_RegexEscape($h)
    Local $query = '{"full": { "$regex": "' & _JSafe($rgx) & '", "$options": "i" }}'
    Local $found = _Mongo_FindOne($pDB, $query, '{"skip":' & $_DB_NextHandles[$h].served & '}', "name")
    If (@error) Then
        return SetError(@error)
    EndIf
    $_DB_NextHandles[$h].served = $_DB_NextHandles[$h].served + 1
    return $found
EndFunc

Func _DB_FileClose($h)
    MapRemove($_DB_NextHandles, $h)
    MapRemove($_DB_OpenFileHandles, $h)
EndFunc

Func __InitFileEntry($sPath, $sDataJSON)
    Local $szDrive, $szDir, $szFName, $szExt
    _PathSplit($sPath, $szDrive, $szDir, $szFName, $szExt)
    Local $modified = @YEAR & '-' & @MON & '-' & @MDAY & 'T' & @HOUR & ':' & @MIN & ':' & @SEC & '.' & @MSEC & _DB_GetGMTBias() ;todo: use correct gmt bias!
    Local $_onInsert = '"$setOnInsert": {"ct": { "$date": "' & $modified & '" }' ;sets creation time only if document does not exist
    Local $_mt = '"mt": { "$date": "' & $modified & '" }'
    ;research shows this is the fastest way to create this with large DataJSON
	Local $s = '{"$set":{' & $_mt & ' ,"name":"'&_JSafe($szFName & $szExt)&'","dir":"'&_JSafe($szDir) & '","full":"'&_JSafe($sPath) & '","data":' & $sDataJSON & '},' & $_onInsert & '}}'
	return $s
EndFunc

Func _DB_RegexEscape($s)
    ;apply regex for mongo search and mimic windows explorer behaviour
    Local $rgx = StringReplace($s,"\","\\")
    $rgx = StringReplace($rgx,".","\.")
    $rgx = StringReplace($rgx,"*",".*")
    return $rgx
EndFunc

Func _DB_FLTAR_EnsureBackslashEnd($sPath, $sDelim="\")
    If StringRight($sPath, 1) <> $sDelim Then
        $sPath &= $sDelim
    EndIf
    Return($sPath)
EndFunc

Func _DB_FLTAR_EnsureBackslashStart($sPath, $sDelim="\")
    If StringLeft($sPath, 1) <> $sDelim Then
        $sPath = $sDelim & $sPath
    EndIf
    Return($sPath)
EndFunc

Func _DB_FLTAR_RegexEscape($s)
    ;apply regex for mongo search and mimic windows explorer behaviour
    Local $rgx = StringReplace($s,"\","\\")
    $rgx = StringReplace($rgx,".","\.")
    $rgx = StringReplace($rgx,"*",".*")
    $rgx = StringReplace($rgx,";","|")
    return $rgx
EndFunc

Func _DB_GetGMTBias()
	Local $s_x, $a_x = _Date_Time_GetTimeZoneInformation()
	Local $i_bias = $a_x[1]
	If $a_x[0] = 1 Then
		$i_bias += $a_x[4]
	ElseIf $a_x[0] = 2 Then
		$i_bias += $a_x[7]
	EndIf
	$i_bias /= 60
	Local $v_data = StringFormat('%.2f', Abs($i_bias))
	$v_data = StringReplace($v_data, '.', ':')
	If StringLen($v_data) = 4 Then $v_data = '0' & $v_data
	If $i_bias <= 0 Then
		$v_data = '+' & $v_data
	Else
		$v_data = '-' & $v_data
	EndIf
	Return $v_data
EndFunc
