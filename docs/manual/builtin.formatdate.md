# FormatDate
Converts date to string using custom format.  

#### Syntax
**FormatDate**\(d, format\)
#### Parameters
_d_
    any valid [date](lang.dates.md) expression 
_format_
    string expression that describes how to format the date. See Remarks section below.
#### Return Value
    string expression containing formatted date
#### Remarks
    `FormatDate()` gives you complete control of the format in which you wish to present date values. Format specification is the same as used in standard C library function `strftime()`.  
  
Format specification can contain any number of special formatting codes \(see below\) in any sequence that are replaced by the corresponding components of the date/time value. Any characters that are not part of formatting codes are copied to the resulting string as is.   
  
Formatting code starts with percent character \(%\) optionally followed by format modifiers and is finished with a letter that specifies type of formatting. Note that the case formatting letters is important.  
  
The following formatting codes are supported:  
  
**%a** | Abbreviated weekday name  
---|---  
**%A** | Full weekday name  
**%b** | Abbreviated month name  
**%B** | Full month name  
**%c** | Date and time representation appropriate for current locale  
**%d** | Day of month as decimal number \(01-31\)  
**%H** | Hour in 24-hour format \(00-23\)  
**%I** | Hour in 12-hour format \(01-12\)  
**%j** | Day of year as decimal number \(001-366\)  
**%m** | Month as decimal number \(01-12\)  
**%M** | Minutes as decimal number \(00-59\)  
**%p** | A.M./P.M. indicator for 12-hour clock  
**%S** | Seconds as decimal number \(00-59\)  
**%U** | Week of year as decimal number, with Sunday as first day of week \(00-53\)  
**%w** | Weekday as decimal number \(0-6; Sunday is 0\)  
**%W** | Week of year as decimal number, with Monday as first day of week \(00-53\)  
**%x** | Date representation for current OS locale  
**%y** | Year without century, as decimal number \(00-99\)  
**%Y** | Year with century, as decimal number  
**%z, %Z** | Time-zone name or abbreviation; no characters if time zone is not known.  
**%%** | Percent sign itself  
  
In most cases you can put **\#** between **%** and formatting letter to suppress leading zeroes, but some systems \(Solaris, for example\) do not support this flag.  
  
Though ShortHand internally relies on operating system functions to format the date, this doesn't mean that Unix date range limitations apply. `FormatDate()` will correctly format any dates in the supported range \(between year 2 AD and year 9999 AD\), no matter what range is supported by operating system. 
#### Example
    
    
        d = date(1809, 2, 13)
        print FormatDate(d, "%A, %b. %d, %Y")  ' prints "Monday, Feb. 13, 1809"
       
        ' let's assume today is September 15, 2002 and local time is 5:30:25 pm  
        d = now()
        print FormatDate(d, "%A, %B %#d, %Y %I:%M:%S %p")  ' "Sunday, September 15, 2002 5:30:25 PM"
        d = date("23:59:59")
        print FormatDate(d, "%m/%d/%y %I:%M %p %Z") ' "15/09/02 11:59 PM Eastern Daylight Time"  
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [Dates](lang.dates.md)
