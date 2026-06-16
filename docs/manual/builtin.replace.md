# replace
Replaces every occurance of string within another string.  

#### Syntax
**replace**\(source, pattern, replacement\)
#### Parameters
_source_
    source string in which to search
_pattern_
    a string to look for
_replacement_
    a string to put into result instead of pattern \(can be empty\)
#### Return Value
    New string with every occurance of `pattern` replaced by `replacement`.
#### Remarks
    `replace()` looks for one string within another and replaces every occurance of it by replacement string. Replacement string can be empty, in which case every occurance of pattern will be removed from resulting string.   
  
This function is case-sensitive.  
  
Present version of ShortHand \(1.0\) doesn't handle Unicode or multi-byte strings.
#### Example
    
    
        s = "The Big Brown Fox"
        print replace(s, "Brown", "Red") ' prints "The Big Red Fox"
        s = "Overdue Amount: $AMOUNT; Please Pay $AMOUNT to avoid disconnection."
        print replace(s, "$AMOUNT", "$185.35")
        ' prints "Overdue Amount: $185.35; Please Pay $185.35 to avoid disconnection."
        
#### Compatibility
    ShortHand **1.0.4** or higher
#### See Also
    [translate](builtin.translate.md)
