# Date
Constructs date value either from calendar components or from string representation of date.  

#### Syntax
**date**\(year,month,day\)  
or  
**date**\(string\) 
#### Parameters
_year, month, day_
    integer expressions that specify year, month and day of month components of the date.  
Valid ranges are:  
`year`:| `2 - 9999`  
---|---  
`month`:| `1 - 12`  
`day`: | `1 - `numbers of days in the specified month of the specified year  
  
_string_
    any expression that is treated as string representation of the date and/or time. See remarks section for description of supported formats.
#### Return Value
    new [date](lang.dates.md) value that corresponds to the constructed date.  
if specified arguments cannot be converted to a valid date, exception is thrown.
#### Remarks
    ShortHand has its own portable dates library and doesn't rely on underlying operating system to perform date/time manipulations \(except for obtaining current date and time zone information\). Therefore, ShortHand is not affected by Unix time limitations \(which only handles dates in from 1970 to 2038\). ShortHand can handle dates from year 2 A.D. up to year 9999 A.D \(see [Dates](lang.dates.md) section for detailed information about dates support\).  
  
The version of the `date` function used is determined by the number of supplied arguments. If three arguments are supplied they are assumed to be year, month and day and first form of function is assumed. If one argument is supplied, it is treated as string representing date and/or time and second form of function is invoked.  
  
Three-argument version sets time part to midnight of the specified date \(00:00:00, or 12:00:00 am\).   
**  
IMPORTANT NOTE:**  
Three-argument form of `date()` function doesn't support two-digit years. If you specify year `2`, it will be treated as year `2 A.D.` \(that is 2000 years ago before year 2002\), **not** `2002` and **not** `1902`. Year `99` will be treated year `99 A.D.`, **not** `1999`. Always use four-digit year when using `date()` function with three arguments.   
  
One-argument version of `date()` function understands dates in any of the following formats:  

    
    [YY]YY-MM-DD [HH:NN:SS]
    HH:NN[:SS]
    
where square brackets \(\[...\]\) mark optional components.   
  
`**YY**` is two-digit year in the range of 0..99 \(current century is assumed\)  
`**YYYY**` is four-digit year \(four-digit year must be in range 2...9999\)  
`**MM**` is one or two-digit month number \(`1...12`\)  
`**HH**` is hour in the range `0...23`.  
`**NN**` is minute in the range `0...59`.  
`**SS**` is second in the range `0...59`.  
  
Delimiters can be any characters that are not digits, not only dash \(`'-'`\) and colon \(`':'`\) characters. Time part can be separated from the date part by any number of space characters.  
When date component is missing \(only time is specified\), current date is assumed. When time part is omitted \(only date is specified\) midnight of that date is assumed \(0:00:00 or 12:00:00 am\). If hours and minutes are defined but seconds are not, seconds are assumed to be zero.  
  
For example, the following expressions that match the above pattern can be used to represent date/time values: \(these examples assume that today is September 15, 2002 and current time is 1:51:03 pm\):  
  
date expression | result \(24-hour notation\)  
---|---  
`2002-09-15` | `September 15, 2002, 00:00:00`  
`2002/09/15 14:00` | `September 15, 2002, 14:00:00`  
`2/9/15` | `September 15, 2002, 00:00:00`  
`04:15` | `September 15, 2002, 04:15:00`  
`99.01.01` | `January 1, 2099, 00:00:00`  
`1999.1.1` | `January 1, 1999, 00:00:00`  
`02-01-01` | `January 1, 2002, 00:00:00`  
  
In addition to the above formats, `date()` function understands all MySQL `TIMESTAMP` formats, which include the following patterns:   
Format | MySQL sub-type | Example | Result  
---|---|---|---  
`YYYYMMDDHHMMSS` | `TIMESTAMP(14)` | 20020915042041 | September 15, 2002, 04:20:41  
`YYMMDDHHMMSS` | `TIMESTAMP(12)` | 990915154059 | September 15, 2099, 15:40:59  
`YYMMDDHHMM` | `TIMESTAMP(10)` | 3909151540 | September 15, 2039, 15:40:00  
`YYYYMMDD` | `TIMESTAMP(8)` | 19990321 | March 21, 1999, 00:00:00  
`YYMMDD` | `TIMESTAMP(6)` | 400318 | March 18, 2040, 00:00:00  
`YYMM` | `TIMESTAMP(4)` | 0211 | November 1, 2002, 00:00:00  
`YY` | `TIMESTAMP(2)` | 04 | January 1, 2004, 00:00:00  
  
This way, `date()` function covers all possible formats that MySQL columns may contain. 
#### Example
    
    
        d = date(2002,11,30)          ' November 30, 2002, 00:00:00
        d = date(1999,1,2)            ' January 2, 1999, 00:00:00
        d = date("2002-09-15")        ' September 15, 2002, 00:00:00
        d = date("01-01-01")          ' January 1, 00:00:00
        d = date("1974/03/18 15:45")  ' March 18, 1974, 15:45:00
        d = date("3.3.18 3:45:59")    ' March 18, 2003, 03:45:59
        d = date("20040318034559")    ' March 18, 2004, 03:45:59
        d = date("8:24")              ' September 15, 2002, 08:24:00 (today)
        d = date("2004")              ' April 1, 2020 00:00:00
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [Dates](lang.dates.md)
