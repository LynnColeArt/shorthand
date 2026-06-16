# length
Returns length of a string  

#### Syntax
**length**\(string\)
#### Parameters
_sting_
    any string expression.
#### Return Value
    length of the string in characters.
#### Remarks
    This function just counts number of characters in the string.   
  
Note that when you deal with literal strings, things like `\n`, `\t`, etc count as single character, because they are a single character.   
  
Present version of ShortHand \(1.0\) doesn't handle Unicode or multi-byte strings.
#### Example
    
    
        n = length("Abra\nCadabra") ' n = 12
        n = length(010) ' n = 2, because 010 is a number that is converted to string "10"
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [strings](lang.string.md)
