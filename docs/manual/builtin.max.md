# max
Determines the largest of two or more numbers  

#### Syntax
**max**\(number1, number2, ...\)
#### Parameters
_number1, number2, ..._
    any numeric expressions. you can specify any number of them, but there must be at least two.
#### Return Value
    largest of two or more numeric expressions
#### Remarks
    If any parameters passed to `max()` are not numbers, they are converted to numbers.
#### Example
    
    
        a = 10
        b = 41
        c = 32
        d = 29  
    
        n = **max**(a, b, c, d) ' n = 41  
    
        n = max("one", "two") ' n = 0 because strings "one" and "two" have numeric value zero
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [min\(\)](builtin.min.md), [Numbers](lang.number.md)
