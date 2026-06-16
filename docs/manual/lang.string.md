# Strings
_String_ in ShortHand is just a sequence of characters.  
Literal strings values look like `"This is a string"` or `'This is a string'`.  
You can use either single quotes or double quotes, the meaning is the same. You can use `""`, `''` or `NULL` to denote empty string. There is no difference between NULL and empty string.  
  
Inside single quoted string you can include bare double quote, and vise versa:  

    
    s1 = "Single Quote ' Inside"
    s2 = 'Double Quote " Inside'
      
---  
  
Back-slash character \(`'\'`\) inside string has special meaning. It is used to include characters like new-line into strings. The following backslash sequences are understood:  
  
`\n` | Carriage Return \(CR\) character \(code 10\)  
---|---  
`\r` | Line Feed \(LF\) character \(code 13\)  
`\t` | TAB character \(code 9\)  
\" | Double Quote \(useful to include double quote into double-quoted string\)  
\' | Single Quote \(useful to include single quote into single-quoted string\)  
\\\ | Backslash character  
  
If backslash is followed by any character not mentioned in this table, backslash will be just removed from the resulting string.  
  

    
    
      print "Line1\nLine2\nLine3"   _' prints three lines_
    
      
---  
  
Current version of ShortHand engine doesn't support Unicode or multi-byte strings. 
#### Compatibility
    ShortHand **1.0.0** or higher
#### See Also  
[Float](builtin.float.md), [String](builtin.string.md), [Int](builtin.int.md), [Date](lang.dates.md)
