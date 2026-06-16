# min
Determines the smallest of two or more numbers  

#### Syntax
**min**\(number1, number2, ...\)
#### Parameters
_number1, number2, ..._
    any numeric expressions. you can specify any number of them, but there must be at least two.
#### Return Value
    smallest of two or more numeric expressions
#### Remarks
    If any parameters passed to `min()` are not numbers, they are converted to numbers.
#### Example
    
    
        a = 10
        b = 41
        c = -32
        d = 29  
    
        n = **min**(a, b, c, d) ' n = -32  
    
        n = min("one", "two") ' n = 0 because strings "one" and "two" have numeric value zero
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [max\(\)](builtin.max.md), [Numbers](lang.number.md)
