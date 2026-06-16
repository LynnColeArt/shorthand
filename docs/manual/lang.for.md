# FOR Loop
FOR Loop repeatedly executes a block of statements for every value in the specified range. FOR Loop has the following syntax:  

    
       **FOR** var = expression1 **TO** expression2
            ...
            statements
            ...
       **END FOR**
    
where `var` is any variable name and `expression1` and `expression2` are any valid expressions that are treated as integer numbers. You don't have to declare or initialize loop variable. It is created automatically if didn't exist before. The value of loop variable after END FOR is value of expression2 at the moment when the loop was started.  
  
For example:   

    
    First 10 products:<br>
    <table> 
      <~ **for** **i=1 to n** ~>
         <tr>
            <td><~@ i ~></td>
            <td><~@ getProductName(i) ~></td>   
         </tr>
      <~ **end for** ~>
    </table>  
---  
  
A block of stements inside FOR \(loop body\) is executed for every integer value in the range `expression1` ... `expression2` inclusively.   
Start and end expressions can have any type, but their values are converted to integer numbers.   
If `expression1` is less than `expression2`, the range is iterated backwards. `FOR i = 10 TO 1` will assign values `10, 9, 8, 7, 6, ... 1` to variable `i`.   
  
Loop expressions are evaluated only once when the loop is started. If expression2, for example, is the value of variable that has value 10 in the beginning, and you change value of that variable in the middle of the loop, the number of iterations will not be affected.   
  

    
       
        limit = 10
        **for** i = 1 **to** limit
              _' This loop will be executed 10 times, not 20_    
              ...
              limit = 20
              ...
        **end for**
      
---  
#### See Also
     [WHILE](lang.while.md), [GRID](lang.grid.md)
