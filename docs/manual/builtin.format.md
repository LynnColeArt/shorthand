# Format
Formats number expression with specified number of digits after decimal point.  

#### Syntax
**Format**\(number, precision\)
#### Parameters
_number_
    any numeric expression \(integer or floating-point\)
_precision_
    number of digits after decimal point to print.
#### Return Value
    formatted string that represents specified numeric value
#### Remarks
    If precision is zero, `Format()` doesn't include fractional part of the number into resulting string and doesn't include dot character. If number doesn't have enough digits after decimal point, the result is padded with zeroes. You can specify any precision, but keep in mind that ShortHand numbers may have at most 15 digits after decimal point.
#### Example
    
    
        x = 100/3.0
        print format(x, 0)    ' prints "33"
        print format(x, 2)    ' prints "33.33"
        print format(500, 2)  ' prints "500.00"
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [numbers](lang.number.md)
