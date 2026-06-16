# strpos
Finds position of one string within another.  

#### Syntax
**strpos**\(source, pattern\)
#### Parameters
_source_
    source string in which to search
_pattern_
    a string to look for
#### Return Value
    zero-based offset of `pattern` within `source`.  
-1 if `pattern` was not found in `source`.
#### Remarks
    `strpos()` looks for one string within another.  
  
This function is case-sensitive.  
  
Present version of ShortHand \(1.0\) doesn't handle Unicode or multi-byte strings.
#### Example
    
    
        s = "The Big Brown Fox"
        print strpos(s, "Brown")   ' prints 8  
        print strpos(s, "brown")   ' prints -1
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [uc](builtin.uc.md)
