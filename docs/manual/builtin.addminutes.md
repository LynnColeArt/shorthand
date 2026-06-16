# AddMinutes
Increments or date value by specified number of minutes.  

#### Syntax
**AddMinutes**\(d, number\)
#### Parameters
_d_
    any valid [date](lang.dates.md) expression 
_number_
    integer number that indicates how many minutes to add \(if positive\) or subtract \(if negative\) from the specified date
#### Return Value
    new [date](lang.dates.md) value that corresponds to incremented or decremented date.  
if parameter d cannot be converted to date, exception is thrown.
#### Remarks
    `AddMinutes` automatically takes care about day, month or year overoll. If you subtract 30 minutes from `January 1st, 2000 12:29 am`, you will get `December 31, 1999, 11:59 pm`
#### Example
    
    
        d = AddMinutes(now(), 30)
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [AddHours](builtin.addhours.md), [AddSeconds](builtin.addseconds.md)
