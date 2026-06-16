# Control Structures
Like any other programming language, ShortHand has control structures that allow programmer to alter the sequence of commands execution.  
Current version of ShortHand has the following control structures:  
  

## IF-THEN-ELSE:
Allows to execute different blocks of code depending on the outcome of condition. See [IF-THEN-ELSE](lang.if.md) topic. 
    
     if product_id != NULL then
        ...
     else
        ...
     end if
      
---  
## FOR Loop
Repeatedly executes a block of code while condition by iterating a variable through the range of values. See [FOR Loop](lang.for.md). 
    
      FOR i=1 TO RecordCount
        ...
      END FOR
      
---  
  

## WHILE Loop:
Repeatedly executes a block of code while condition is TRUE. See [WHILE Loop](lang.while.md). 
    
     while not f.eof()
        ...
     end while
      
---  
## GRID
Grid is a special type of loop designed specifically for iterating through recordsets of data, most commonly used to produce HTML tables based on database queries. Separate [Grid](lang.grid.md) section describes GRID syntax and usage in details. 
    
    <~ GRID( products ) ~>  
       <TR BGCOLOR="<~@bg~>">  
           <TD valign="top"><~@prod.id~></TD>  
           <TD valign="top"><IMG SRC="<~@prod.picture~>" VSPACE=4 HSPACE=8></TD>  
           <TD valign="top"><~@prod.name~></TD>  
           <TD valign="top"><B>$<~@prod.price~></B></TD>  
       </TR>
    <~ END GRID ~>  
---
