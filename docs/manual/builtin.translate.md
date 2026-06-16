# translate
Replaces every occurance of a character within a string with another character.  

#### Syntax
**translate**\(source, ch1, ch2\)
#### Parameters
_source_
    source string in which to search
_ch1_
    a character to look for; this can be any string, but only its first character will be used
_ch2_
    replacement character; this can be any string, but only its first character will be used
#### Return Value
    New string with every occurance of character `ch1` replaced by character `ch2`.
#### Remarks
    `translate()` looks for one character within a string and replaces every occurance of it by another character. Both `ch1` and `ch2` may be any string that contain at least one character. `translate` is similar to [replace\(\)](builtin.replace.md), but it is more efficient if you need only to translate characters.   
  
This function is case-sensitive.  
  
Present version of ShortHand \(1.0\) doesn't handle Unicode or multi-byte strings.
#### Example
    
    
        s = "The Big Brown Fox"
        print translate(s, "B", "b") ' prints "The big brown Fox"
        s = "The Big Brown Fox"
        print translate(s, " ", "\n") ' replaces space by new-line
        ' prints every word on a separate line
        
#### Compatibility
    ShortHand **1.0.4** or higher
#### See Also
    [replace](builtin.replace.md)
