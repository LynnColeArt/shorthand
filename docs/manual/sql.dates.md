# Dates in SQL
ShortHand doesn't have any special support for SQL DATE types. Date fields, like any other data fields, are fetched from and inserted to the database as strings. It is your responsibility to interpret date fields as date values and properly format parameters that will go into date fields.  
  
ShortHand makes this task easier by offering powerful portable dates arithmetic \(see [Dates](lang.dates.md)\) and conversion functions. [Date\(\)](builtin.date.md) built-in function understand all variations of DATE, DATETIME and TIMESTAMP types of MySQL and converts them to date values that can be manipulated using different date functions or presented in any text format according to your application needs.  
  
  

    
       rs = new RecordSet(db, "SELECT expires FROM membership WHERE id = :id")
       rs.execute()
       rs.next()
    
       ' field 'expires' can be of DATE, DATETIME or any TIMESTAMP type
       ' date() function performs necessary conversions
       expDate = date(rs.expires)
    
       print "Membership expires on "& FormatDate("%m/%d/%Y")
    
       ....
       expDate = expDate + 7   ' Add one week to the date
       updator = new DDL(db, "UPDATE membership SET expires = ? WHERE id = :id")
       updator.execute(expDate)
      
---  
  
By default, like in the example above, dates are converted to strings using format `"D Mon YYYY, HH:MM AM/PM"` \(for example, `"24 Sep 2002, 8:50 PM"`\). If you are not sure if database engine understands this format, you if you want full control over how dates are inserted into the database, use [FormatDate\(\)](builtin.formatdate.md) function to explicitly format date values.  
  
Default MySQL format is `"YYYY-MM-DD HH:MM:SS"` \(using 24-hour notation\). To cast date value to this format explicitly, use the following syntax:  

    
       ....
       expDate = expDate + 7   ' Add one week to the date
       updator = new DDL(db, "UPDATE membership SET expires = ? WHERE id = :id")
       updator.execute(FormatDate(expDate,  "%Y-%m-%d %H:%M:%S" ))  
---
