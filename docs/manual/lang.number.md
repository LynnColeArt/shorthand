# Numbers
ShortHand supports signed integer and floating-point numbers provided by underlying operating system. On all 32-bit systems for which current version of ShortHand engine exists, these numbers have the following ranges:  
  
Integer:  | -2147483648 ... +2147483647 \(32-bit integer\)  
---|---  
Float:  | +/- 1.7·10-308 ... 1.7·10308, with 15-digit precision \(64-bit floating point number\)  
  
ShortHand automatically takes care about type conversions in arihmetic operations. The only thing you should be concerned about is division. When both arguments are integer numbers, the division is integer. 5637/100 will produce 56. If you want to get true decimal division, cast one of arguments to floating point number by adding 0.0 to it.  

    
    <~  
        b = 5637
        c = 100
    
        a = b / c   _' integer division_
        print a   _' will produce "56"_
    
        a = (b + 0.0) / c   _' forces floating-point arithmetic_
        print a   _' will produce "56.37"_
    ~>
      
---  
  

#### Compatibility
    ShortHand **1.0.0** or higher
#### See Also  
[Float](builtin.float.md), [String](builtin.string.md), [Int](builtin.int.md), [Date](lang.dates.md)
