# substring
Returns specified portion of a string.  

#### Syntax
**substring**\(source, start \[,length\]\)
#### Parameters
_source_
    source string
_start_
    beginning offset of a portion \(zero-based\)
_length_
    optional - maximum number of chatracters to take
#### Return Value
    new string that is part of original string.  
empty string if specified range is out of bounds
#### Remarks
    `substring()` returns portion of original string at specified offset and having specified length.  
  
Parameter `length` is optional and specifies maximum number of characters to return. If `length` is not specified or is -1, everything from the specified offset until the end of string is returned.  
If original string contains less characters than required, all available characters are returned from the specified offset.  
  
`start` parameter can be negative, which means an offset from the end of the string. If absolute value of negative offset is greater than length of the string, the function starts at the beginning of the string.  
  
If combination of start and length describes invalid range, the result is empty string.  
  
Present version of ShortHand \(1.0\) doesn't handle Unicode or multi-byte strings.
#### Example
    
    
        s = "The Big Brown Fox"
    
        print substring(s, 0, 7)   ' prints "The Big"
        print substring(s, 5, 3)   ' prints "Big"
        print substring(s, 8)      ' prints "Brown Fox"
        print substring(s, 8, 100) ' prints "Brown Fox"
        print substring(s, -3)     ' prints "Fox"
        print substring(s, -9, 5)  ' prints "Brown"
    
        print substring(x_Card_Number, -4)   ' prints last 4 digits of credit card number  
        
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [strpos\(\)](builtin.strpos.md), [length\(\)](builtin.length.md)
