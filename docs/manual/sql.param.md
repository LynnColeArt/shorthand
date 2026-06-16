# Parametrized SQL
ShortHand engine helps you to automate common SQL tasks by offering parametrized SQL statements functionality. Without it, if you want, for example, to insert some data into database table, you would write something like this \(you still can do it\):  
  

    
       gbInsert = new DDL(db, "INSERT INTO guestbook VALUES('"&name&"','"&currentDate&"', '"&comments&"'")
       gbInsert.execute()
      
---  
  
Instead, you can make code more readable and robust by using parametrized SQL. The above example in this case would look like this:   
  

    
       gbInsert = new DDL(db, "INSERT INTO guestbook VALUES(:name, :currentDate, :comments")
       gbInsert.execute()
      
---  
  
Or like this:   
  

    
       gbInsert = new DDL(db, "INSERT INTO guestbook VALUES(?, ?, ?)")
       gbInsert.execute(name, currentDate, comments)
      
---  
  
Whenever you put **:var** expression in the text of your SQL statement \(this syntax is often referred to as _host variables_ in SQL\), ShortHand replaces it by the value of ShortHand variable **var** , propertly escaped and enclosed in quotes.   
  
Whenever you put question marks \(**?**\) in the SQL text, ShortHand subsequently replaces all question marks by values of parameters passed to `Execute()` method. If you used three question marks, you must also pass exactly three parameters to `Execute()` method like in the example above.   
  
ShortHand automatically picks up proper mechanism supported by underlying DBMS to pass parameters to SQL engine.   
For MySQL driver, ShortHand treats each substitutable parameter as string and when it constructs actual SQL statement, it surrounds the value by single quote characters and translates any sequences within the string that may confuse SQL engine \(like new-lines, single quotes, etc\) into format understood by DBMS.  
  
For example, imagine that the following text has been posted to your application using HTML Form:   

    
    I've been frozen for 30 years. 
    I've got to see if my bits and pieces are still working. 
      
---  
  
When you use parameterized SQL statement like:  
` INSERT INTO quotes VALUES(:quote) `  
against MySQL database,  
ShortHand will internally translate it to the following before sending to the server:  

    
    INSERT INTO quotes 
    VALUES('I\'ve been frozen for 30 years.\nI\'ve got to see if my bits and pieces are still working.')
      
---  
  
  
The values of hosts variable are taken at the moment when RecordSet or DDL object performs method [Execute\(\)](sql.execute.md) or during first iteration of [GRID](lang.grid.md) loop, not at the moment when the object is constructed:   
  
For example:   

    
       x = 5
       q = new DDL(db, "INSERT INTO foo VALUES(:x)")
       x = 10
       q.execute() ' will insert 10, not 5
       x = 20
       q.execute() ' will insert 20
      
---  
  
When evaluating variables, ShortHand follows normal scoping rules \(see [Variables](lang.variables.md)\). If you execute parametrized SQL from your function, local variable names or parameters will take precedence over global variables with the same names:  
  

    
       x = 5
       inserter = new DDL(db, "INSERT INTO foo VALUES(:x)") 
    
       function doInsert(x)
          ' will use parameter x, not global variable x
          inserter.execute()
       end function
    
       x = 10
       q.execute()   ' will insert 10
       doInsert(44)  ' will insert 44  
---  
  
The advange of using host variable syntax over question marks is that SQL is more readable and you can mention one variables many times within the same SQL \(`"INSERT INTO bar(col1, col2) VALUES (:var, :var)"`\).  
The advantage of using question marks is that you avoid potential name conflicts between global and local variables and do not hard-code any ShortHand names into SQL statements.  
  
You can combine host variables syntax \(`:var`\) and question marks within the same statement:  
  

    
       function getPreference(prefName, prefVersion)
           ' we assume that uid is globally available variable
           q = new RecordSet(db, "SELECT * FROM preference WHERE uid=**:uid** AND name = **?** AND version >= **?** ")
           q.execute(prefName, prefVersion)
           if q.next() then
               return q.value("data")
           end if
       end function
      
---
