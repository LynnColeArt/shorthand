# rand
Generates pseudo-random number.  

#### Syntax
**rand**\(\)  
**rand**\(maximum\)  
**rand**\(minimum, maximum\) 
#### Parameters
_minimum, maximum_
    if these values are passed, they must be numeric expressions that specify range of generated random number \(fractional values are rounded up to the nearest integers\)
#### Return Value
    random integer number that is restricted to the specified range 
#### Remarks
    if no range is specified, the number is generated in the range 0...2147483647 \(the latter value is maximum possible positive 32-bit integer\).  
  
if only one argument is passed \(`maximum`\), the number is generated in the range `0...maximum`.  
  
if two arguments are passed \(`minimum` and `maximum`\), they define the range. 
#### Example
    
    
    '
    ' function that generates random 24-digit session ID
    '
    function generateSessionID()
    
       local sid = ""
       while (length(sid) < 24)
         sid = sid & (1000000+**rand**(999999))
       end while
    
       if length(sid) > 24 then
          sid = substring(sid, 0, 24)
       end if
       return sid
    
    end function
    
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
