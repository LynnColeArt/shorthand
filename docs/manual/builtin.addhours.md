# AddHours
Increments or date value by specified number of hours.  

#### Syntax
**AddHours**\(d, number\) 
#### Parameters
_d_
    any valid [date](lang.dates.md) expression 
_number_
    integer number that indicates how many hours to add \(if positive\) or subtract \(if negative\) from the specified date
#### Return Value
    new [date](lang.dates.md) value that corresponds to incremented or decremented date.  
if parameter d cannot be converted to date, exception is thrown.
#### Remarks
    `AddHours` automatically takes care about day, month or year overoll. If you subtract 4 hours from `January 1st, 2000 2:31 am`, you will get `December 31, 1999, 10:31 pm`. Hours value doesn't have to be in the range from 0 to 23 - it can be any valid integer number. 72 hours means 3 days, and so on. If you specify fractional hours value the number is rounded up or down to the nearest integer.
#### Example
    
    
        d = AddHours(now(), 12)
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [AddMinutes](builtin.addminutes.md), [AddSeconds](builtin.addseconds.md)
