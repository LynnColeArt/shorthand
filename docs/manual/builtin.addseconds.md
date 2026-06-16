# AddSeconds
Increments or date value by specified number of seconds.  

#### Syntax
**AddSeconds**\(d, number\)
#### Parameters
_d_
    any valid [date](lang.dates.md) expression 
_number_
    integer number that indicates how many seconds to add \(if positive\) or subtract \(if negative\) from the specified date
#### Return Value
    new [date](lang.dates.md) value that corresponds to incremented or decremented date.  
if parameter d cannot be converted to date, exception is thrown.
#### Remarks
    `AddSeconds` automatically takes care about day, month or year overoll. If you subtract 30 seconds from `January 1st, 2000 12:00:01 am`, you will get `December 31, 1999, 11:59:31 pm`. The number of seconds doesn't need to below 60. You can use any valid integer number. For example, the value of `86400` seconds will add or subtract one day. 
#### Example
    
    
        d = AddSeconds(now(), 30)
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [AddMinutes](builtin.addminutes.md), [AddHours](builtin.addhours.md)
