# exit
Stops execution of current ShortHand program and any parent ShortHand scripts.  

#### Syntax
**exit**\(\)
#### Parameters
    none
#### Return Value
    none
#### Remarks
    `exit()` function immediately stops execution of current ShortHand script and all parent scripts if current script has been included into some other file, as though the end of ShortHand file has been reached. Any ShortHand statements and/or unescaped HTML following `exit()` command are not executed or printed.  
  
`exit()` function can be useful when you wish to interrupt normal control flow of current ShortHand script to indicate some error condition, or when you have already produced complete HTML page and wish to stop any futher processing.  
  
Keep in mind that if current program has already produced `<HTML>,<BODY>` or other HTML tags and corresponding closing tags \(`</BODY>`, `</HTML>`, etc\) have not been sent yet, some browsers \(especially early versions of Netscape, like Netscape 4.X\) may not render resulting HTML code correctly.
#### Example
    
    
        exit()
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [redirect\(\)](builtin.redirect.md)
