
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