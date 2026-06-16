# CONTINUE
CONTINUE operator stops current iteration of FOR, FOREACH, WHILE or GRID loop and skips to the next iteration.  
  
For example:   

    
      _' read file line by line and skip all lines starting with '#'_
      while not f.eof()
          s = f.readln()
          if substring(s, 0, 1) = '#' then 
             **continue**
          end if
          _' do something with the line_
          ....
      end while
      
---  
  
CONTUNUE skips all statements down to the end of loop and transfers control to the beginning of the loop. If loop condition is not satisfied, the loop is finished.  
  
See Also: [BREAK](lang.break.md), [FOR](lang.for.md), [FOREACH](lang.foreach.md), [WHILE](lang.while.md), [GRID](lang.grid.md)
