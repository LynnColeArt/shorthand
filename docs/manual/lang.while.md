# WHILE Loop
WHILE statement repeatedly executes a block of statements inside a loop while loop condition evaluates to TRUE. WHILE loop has the following syntax:  

    
       **WHILE** condition
             ...
             statements
             ...
       **END WHILE**
    
Condition is any valid [boolean expression](lang.boolean.md) and statements within the loop can be any valid [statements](lang.statements.md), including nested loops. Number of times the loop body is executed is generally not known when the loop is started. Unlike [FOR](lang.for.md) loop, WHILE loop evaluates condition before every iteration, so that outcome of condition can be affected by actions inside loop. If condition is FALSE at the time when the loop is started, the body of the loop is never executed.   
  
Example:   

    
    _' the following code reads contents of the file
      ' and prints every line preceeded by line number:_
      f = new File(fileName, "r")
      _' read the file line by line and display each line_    
    
      i = 1
      **while** not f.eof()
          s = f.readln()
          println "Line " & i& ": " & s
          i = i + 1
      **end while**
      f.close()
    
      
---
