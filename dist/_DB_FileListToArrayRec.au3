
#include <Array.au3>

#include "MongoDB_UDF\MongoDB.au3"
#include "MongoDB_UDF\MongoDB_SimpleJson.au3"

_Mongo_Init(@ScriptDir & "\MongoDB_UDF\")

Local $s_mongo_url 		= "mongodb://localhost:27017"
Local $s_mongo_database_name 	= "ffastrans"
Local $s_mongo_collection_name 	= "configs"
Local $pMCCONFIGS = _Mongo_CreateCollection($s_mongo_url, $s_mongo_database_name, $s_mongo_collection_name)

_DB_FileListToArrayRec($pMCCONFIGS,"configs","*|ffas*|workflows",1,$FLTAR_RECUR)

Func _DB_FileListToArrayRec($pDB, $sFilePath , $sMask = "*" , $iReturn = 1 , $iRecur = $FLTAR_NORECUR , $iSort = $FLTAR_NOSORT , $iReturnPath = $FLTAR_RELPATH)
    ;$sMask = Include|Exclude|Exclude_Folders
    If ($iReturn <> 1) Then 
        return SetError(1) 
    EndIf
    If ($iRecur < 0) Then 
        return SetError(2) 
    EndIf
    
    Local $aMask = StringSplit ($sMask,'|')
    Local $sInc     = $aMask[0] > 0 ? $aMask[1] : "*"
    Local $sExc     = $aMask[0] > 1 ? $aMask[2] : ""
    Local $sIncDir  = $aMask[0] > 2 ? $aMask[3] : ""
 
    ;~ NAME SEARCH
    
    $sInc = _DB_FLTAR_RegexEscape("^" & $sInc & "$")
    Local $s_name_exc_rgx = $sExc
    If ($sExc <> "") Then
        $sExc = _DB_FLTAR_RegexEscape("^" & $sExc & "$")
    EndIf
    If ($sIncDir <> "") Then
        $sIncDir = _DB_FLTAR_RegexEscape($sIncDir)
    EndIf
    ;~ PATH SEARCH
    $sFilePath = _DB_FLTAR_EnsureBackslashEnd($sFilePath)
    Local $s_dirrgx = $sFilePath

    ;~ RECURSE
    If ($iRecur = $FLTAR_NORECUR) Then
        $s_dirrgx = "^" & $sFilePath & "$"
    EndIf
    $s_dirrgx = _DB_FLTAR_RegexEscape($s_dirrgx)

    ;Construct query
    Local $query = '{'
    $query &= '"dir": { "$regex": "' & _JSafe($s_dirrgx) & '", "$options": "i" }'
    $query &= ',"name": { "$regex": "' & _JSafe($sInc) & '", "$options": "i" }'
    If ($sExc <> "") Then
        $query &= ',"name": {"$not": {"$regex": "' & _JSafe($sExc) & '", "$options": "i" }}'
    EndIf
    If ($sIncDir <> "") Then
        $query &= ',"dir": {"$not": {"$regex": "' & _JSafe($sIncDir) & '", "$options": "i" }}'
    EndIf
    $query &= '}'

    Local $sOpts = "{}"
    If $iSort = $FLTAR_NOSORT Then
        $sOpts = '{"sort": {"name":1}}'
    EndIf

    ;Exec query
    ConsoleWrite("QUERY " & $query & @CRLF)
    MsgBox(0,0,0)
    Local $cnt =  _Mongo_CountDocs($pDB,$query)
    MsgBox(0,0,$cnt)
    Local $pCursor = _Mongo_FindMany($pDB,$query,$sOpts)
    If (@error) Then
        Exit(300)
    EndIf
    
    Local $aCursor = _Mongo_Cursor_To_Array($pCursor,"full")
    If (@error) Then
        Exit(400)
    EndIf

    _ArrayDisplay($aCursor)
    

EndFunc

Func _DB_FLTAR_EnsureBackslashEnd($sPath, $sDelim="\")
    If StringRight($sPath, 1) <> $sDelim Then
        $sPath &= $sDelim
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
