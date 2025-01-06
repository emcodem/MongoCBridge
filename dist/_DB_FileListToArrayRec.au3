
#include <Array.au3>
#include "MongoDB_UDF\MongoDB_Test.au3"
#include "MongoDB_UDF\MongoDB.au3"

_DB_FileListToArrayRec("C:\temp","*.json|excl|temp")

Func _DB_FileListToArrayRec($sFilePath , $sMask = "*" , $iReturn = $FLTAR_FILESFOLDERS , $iRecur = $FLTAR_NORECUR , $iSort = $FLTAR_NOSORT , $iReturnPath = $FLTAR_RELPATH)
    ;$sMask = Include|Exclude|Exclude_Folders
    If ($iReturn <> 1) Then 
        return SetError(1) 
    EndIf
    If ($iRecur < 0) Then 
        return SetError(2) 
    EndIf
    
    Local $aMask = StringSplit ($sMask,'|')[1]
    Local $sInc     = $aMask[0] > 0 ? $aMask[1] : "*"
    Local $sExc     = $aMask[0] > 1 ? $aMask[2] : ""
    Local $sIncDir  = $aMask[0] > 2 ? $aMask[3] : ""
 
    _ArrayDisplay($aMask)
    
    ConsoleWrite("Include "& $sInc &@CRLF)

EndFunc
