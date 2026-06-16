# lc
Converts string to lower case.  

#### Syntax
**lc**\(string\)
#### Parameters
_string_
    any string expression
#### Return Value
    argument converted to lower case.
#### Remarks
    `lc()` converts all characters in the string to lower case.  
  
This function relies on the operating system to perform character conversion. If operating system has local settings properly set up and configured, this function will also handle non-English characters specific to current locale. Otherwise the result of convertion of non-English characters is undefined.  
  
Present version of ShortHand \(1.0\) doesn't handle Unicode or multi-byte strings.
#### Example
    
    
        s = "The Big Brown Fox"
        print lc(s)   ' prints "the big brown fox"
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [uc](builtin.uc.md)
