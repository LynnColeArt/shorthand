# uc
Converts string to upper case.  

#### Syntax
**uc**\(string\)
#### Parameters
_string_
    any string expression
#### Return Value
    argument converted to upper case.
#### Remarks
    `uc()` converts all characters in the argument string to lower case and returns new string.  
  
This function relies on the operating system to perform character conversion. If operating system has local settings properly set up and configured, this function will also handle non-English characters specific to current locale. Otherwise the result of convertion of non-English characters is undefined.  
  
Present version of ShortHand \(1.0\) doesn't handle Unicode or multi-byte strings.
#### Example
    
    
        s = "The Big Brown Fox"
        print uc(s)   ' prints "THE BIG BROWN FOX"
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [lc](builtin.lc.md)
