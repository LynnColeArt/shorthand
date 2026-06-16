# Dates
ShortHand can handle dates in the range of January 1, Year 2 BC to December 31, Year 9999 AD, which may be not enough for advanced astronomical applications, but is more than sufficient for anything else. ShortHand doesn't use calendar system the underlying operating system for dates arithmetic, so that Unix limitations _do not_ apply to the dates handled by ShortHand \(32-bit Unix systems can only handle dates between January 1, 1970 and January 1, 2038\).  
  
Date values in ShortHand include date and time of day part with seconds precision \(no milliseconds\). There are two ways to create date values: use built-in function [date\(\)](builtin.date.md) or to use built-in function now\(\). All other date values are derived from these values produced by these functions.   
  
date\(\) function has two forms - one that takes three arguments - year, month and day, another that takes one argument that converts string representation of date and/or time to ShortHand date value. Manual page for function [date\(\)](builtin.date.md) contains detailed description of supported date formats.  
  
Examples of date constuctors:   

    
    d = date(2002,11,31) ' constructs date October 31, 2002
    d = date("2039-05-28 14:35") ' converts string to date
    d = AddSeconds(now(), 30)  ' adds 30 seconds to current time  
      
---  
## Date Conversions
You can use date values in arithmetic or string expressions. Intenally in ShortHand engine every date is presented as two numbers - Julian Day Number \(JDN - number of days since January 1st, 4712 BC\) which corresponds to date part and number of seconds since midnight on that date.   
  
When you perform arithmetic operations \(+,-\) that involve dates and numbers, dates are converted to integers as Julian Day Numbers. This has two important implications:  

  1. You can add or subtract integer numbers to/from date values. This would mean to add or subtract specified number of days.   
For example:   

        d1 = now() + 45 ' d1 is date that is 45 days from now   
    d2 = now() - 14  ' d2 is the same day two weeks ago
    
See also [AddSeconds\(\)](builtin.addseconds.md), [AddMinutes\(\)](builtin.addminutes.md), [AddHours\(\) ](builtin.addhours.md), [Float\(\)](builtin.float.md), [String\(\)](builtin.string.md), [Int\(\)](builtin.int.md)  
---  
  

  2. You can subtract one day from another to learn difference between two dates in days. For example:   

           rs = RecordSet(db, "SELECT modified FROM documents WHERE id = :id")   
       rs.execute()
       modified = rs.value("modified")
       print "Document was modified " &  now() - modified  & " days ago"
      
---  

When there is a need to convert date to string, date is converted to string using default format, which is `"D Mon YYYY, HH:MM AM/PM"`. If this is format is not good for you, format date explicitly using [FormatDate\(\)](builtin.formatdate.md) function.  
  

    
      d = date(2002,09,14)
      println d  _' will print "14 Sep 2002, 12:00 AM"_
      println FormatDate(d, "%A, %B %d, %Y") _' will print "Saturday, September 14, 2002"_
      
---
