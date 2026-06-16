# Assignment
Assignment operator _assigns_ a value of expression to a variable. Assignment has form `"var = expression"`. Assignment also creates a variable if it didn't exist before. Any old value that variable had before is lost \(or it is _detached_ from the variable if variable has object value\). Expression on the right side of '=' can be any valid expression of arbitrary complexity \(See [Expressions](lang.expressions.md)\).   
  
Examples of assignments:   

    
      _' assigns 3.1456 to variable pi_
      pi **=** 3.1456 
    
      _' creates new Connection object and assigns object 
      ' value to the variable conn_  
      conn = new Connection("MYSQL", "database=db1;uid=demo;")
      
      _' constructs string and assigns result to the variable s_
      str **=** "size of " & fname & " = "& FileSize(fname) & " bytes"
    
      _' assigns current time + 1 day to the variable tomorrow_
      tomorrow **=** now() + 1
      
---  
  
Note that that when you construct an object and assign it to a variable \(like variable `conn` in the example above\), the only way to access the object is through this variable. You can assign value of object variable to another variable, but if you re-assign zero, for example to variable `conn`, object will not longer be accessible through variable `conn`.
