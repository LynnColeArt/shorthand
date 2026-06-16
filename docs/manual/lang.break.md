# BREAK
Break statement immediately interrupts execution of current loop \(**FOR** , **WHILE** or **GRID**\) and transfers control to the first statement outside the loop.  
  
If there are nested loops, **BREAK** affects only innermost loop where it is used. You have to include extra BREAK into you code if you wish to interrupt outer loop.  
  
For example:   

    
    <~ 
       ' print at most first 25 lines of file  
       lineNumber = 1
       **while** not eof(f)
           println f.readln()
           lineNumber = lineNumber + 1
           if lineNumber >= 25 then
              **break**
           end if
       **end while**
    ~>
      
---  
  
More advanced example. The following piece of code:  

    
    <TABLE border="0" cellspacing=1 cellpadding=3>
    <~ FOR i=1 TO 10
          print "<TR>"
          **FOR** j=1 TO 10
             IF i+j > 11 THEN
                 **BREAK** _' breaks inner loop (j=1 TO 10)_
             END IF
             IF (i+j) % 2 = 0 THEN
                BG = "BGCOLOR=\"#C3C3C3\""
             ELSE
                BG = ""
             END IF
             print "<TD "&BG&" ALIGN=RIGHT>" & (i * j) & "</TD>\n"  
          **END FOR**
          print "</TR>\n"
       END FOR ~>
    </TABLE>
      
---  
  
Will produce the following HTML table that is partial multiplication table of numbers 1 through 10.  
1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10  
---|---|---|---|---|---|---|---|---|---  
2 | 4 | 6 | 8 | 10 | 12 | 14 | 16 | 18  
3 | 6 | 9 | 12 | 15 | 18 | 21 | 24  
4 | 8 | 12 | 16 | 20 | 24 | 28  
5 | 10 | 15 | 20 | 25 | 30  
6 | 12 | 18 | 24 | 30  
7 | 14 | 21 | 28  
8 | 16 | 24  
9 | 18  
10
