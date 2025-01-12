#include-once
#Region Simple Json helpers

Func _MakeIndexCmd($to_index,$idx_name,$collname,$unique = "false");$unique="true"|"false"
    return '{"createIndexes": "'&$collname&'","indexes": [{"key":{ "' & $to_index & '": 1 },"name": "'&$idx_name&'","unique": ' & $unique & '}]}'
EndFunc

Func _Jkv($key,$val)
	return StringFormat('{"%s":"%s"}', _JSafe($key), _JSafe($val))
EndFunc

Func _Jkj($key,$val)
	return StringFormat('{"%s":%s}', _JSafe($key), $val)
EndFunc

Func _JSafe($sString)
    
    ; Escape JSON special characters rfc8259  like 
    Local $pattern = '([\x{0022}\x{005C}\x{002F}])' ;", \, /, 
    Local $replacement = "\\$1"
    $sString = StringRegExpReplace($sString, $pattern, $replacement)

    ;\b, \f, \n, \r, \t == (\x{0008}\x{000C}\x{000A}\x{000D}\x{0009}) must be replaced by their string literals
    $pattern = '([\x{0008}])'
    $replacement = "\\b"
    $sString = StringRegExpReplace($sString, $pattern, $replacement)
    $pattern = '([\x{000C}])'
    $replacement = "\\f"
    $sString = StringRegExpReplace($sString, $pattern, $replacement)
    $pattern = '([\x{000A}])'
    $replacement = "\\n"
    $sString = StringRegExpReplace($sString, $pattern, $replacement)
    $pattern = '([\x{000D}])'
    $replacement = "\\r"
    $sString = StringRegExpReplace($sString, $pattern, $replacement)
    $pattern = '([\x{0009}])'
    $replacement = "\\t"
    $sString = StringRegExpReplace($sString, $pattern, $replacement)
    return $sString
    
EndFunc

;~ Func _JSafe($sString)
;~     ; Initialize the escaped string
;~     Local $sEscapedString = ""

;~     ; Loop through each character in the input string
;~     For $i = 1 To StringLen($sString)
;~         Local $char = StringMid($sString, $i, 1)

;~         ; Check for special JSON characters and escape them
;~         Switch $char
;~             Case '"'
;~                 $sEscapedString &= '\"'
;~             Case '\'
;~                 $sEscapedString &= '\\'
;~             Case '/'
;~                 $sEscapedString &= '\/'
;~             Case Chr(8) ; Backspace
;~                 $sEscapedString &= '\b'
;~             Case Chr(12) ; Formfeed
;~                 $sEscapedString &= '\f'
;~             Case Chr(10) ; Newline
;~                 $sEscapedString &= '\n'
;~             Case Chr(13) ; Carriage return
;~                 $sEscapedString &= '\r'
;~             Case Chr(9) ; Tab
;~                 $sEscapedString &= '\t'
;~ 			Case Else    ; If the character is non-printable, encode it as \uXXXX
;~                 If Asc($char) < 32 Or Asc($char) > 126 Then
;~                     $sEscapedString &= "\\u" & StringFormat("%04X", Asc($char))
;~                 Else
;~                     ; Otherwise, append the character as is
;~                     $sEscapedString &= $char
;~                 EndIf
;~         EndSwitch
;~     Next

;~     Return $sEscapedString
;~ EndFunc


Func _JBase64Decode($input_string)
    
    Local $struct = DllStructCreate("int")
    
    Local $a_Call = DllCall("Crypt32.dll", "int", "CryptStringToBinary", _
            "str", $input_string, _
            "int", 0, _
            "int", 1, _
            "ptr", 0, _
            "ptr", DllStructGetPtr($struct, 1), _
            "ptr", 0, _
            "ptr", 0)

    If @error Or Not $a_Call[0] Then
        Return SetError(1, 0, "") ; error calculating the length of the buffer needed
    EndIf

    Local $a = DllStructCreate("byte[" & DllStructGetData($struct, 1) & "]")

    $a_Call = DllCall("Crypt32.dll", "int", "CryptStringToBinary", _
            "str", $input_string, _
            "int", 0, _
            "int", 1, _
            "ptr", DllStructGetPtr($a), _
            "ptr", DllStructGetPtr($struct, 1), _
            "ptr", 0, _
            "ptr", 0)
    
    If @error Or Not $a_Call[0] Then
        Return SetError(2, 0, ""); error decoding
    EndIf

    Return DllStructGetData($a, 1)
    
EndFunc   ;==>_Base64Decode

Func _JBase64Encode($input)
    
    $input = Binary($input)
    
    Local $struct = DllStructCreate("byte[" & BinaryLen($input) & "]")
    
    DllStructSetData($struct, 1, $input)
    
    Local $strc = DllStructCreate("int")
    
    Local $a_Call = DllCall("Crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($struct), _
            "int", DllStructGetSize($struct), _
            "int", 1, _
            "ptr", 0, _
            "ptr", DllStructGetPtr($strc))
    
    If @error Or Not $a_Call[0] Then
        Return SetError(1, 0, "") ; error calculating the length of the buffer needed
    EndIf
    
    Local $a = DllStructCreate("char[" & DllStructGetData($strc, 1) & "]")
    
    $a_Call = DllCall("Crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($struct), _
            "int", DllStructGetSize($struct), _
            "int", 1, _
            "ptr", DllStructGetPtr($a), _
            "ptr", DllStructGetPtr($strc))
    
    If @error Or Not $a_Call[0] Then
        Return SetError(2, 0, ""); error encoding
    EndIf
    Local $to_return = DllStructGetData($a, 1)
    
    Return StringReplace($to_return,@CRLF,"","")

EndFunc   ;==>_Base64Encode


#EndRegion Simple JSON helpers